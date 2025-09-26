-- PostgreSQL + PostGIS データベーススキーマ
-- ツーリングマップアプリ用

-- PostGIS拡張を有効化
CREATE EXTENSION IF NOT EXISTS postgis;

-- ユーザーテーブル
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    handle TEXT UNIQUE NOT NULL,
    display_name TEXT,
    icon_url TEXT,
    privacy_level TEXT NOT NULL DEFAULT 'standard' CHECK (privacy_level IN ('strict', 'standard', 'open')),
    home_geom GEOMETRY(Point, 4326),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ルートテーブル
CREATE TABLE routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    geom GEOMETRY(MultiLineString, 4326) NOT NULL,
    distance_m INTEGER,
    elev_gain_m INTEGER,
    tags TEXT[] DEFAULT '{}',
    visibility TEXT NOT NULL DEFAULT 'private' CHECK (visibility IN ('public', 'unlisted', 'private')),
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ウェイポイントテーブル
CREATE TABLE waypoints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    seq INTEGER NOT NULL,
    name TEXT,
    desc TEXT,
    geom GEOMETRY(Point, 4326) NOT NULL
);

-- ルート添付ファイルテーブル
CREATE TABLE route_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    kind TEXT NOT NULL CHECK (kind IN ('gpx_route', 'gpx_track', 'gpx_waypoints', 'kml')),
    url TEXT NOT NULL,
    checksum TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- スポットテーブル
CREATE TABLE spots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    geom GEOMETRY(Point, 4326) NOT NULL,
    name TEXT NOT NULL,
    tags TEXT[] NOT NULL DEFAULT '{}',
    open_hours_json JSONB,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ヤエーイベントテーブル
CREATE TABLE yae_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_a UUID NOT NULL REFERENCES users(id),
    user_b UUID NOT NULL REFERENCES users(id),
    geom GEOMETRY(Point, 4326) NOT NULL,
    happened_at TIMESTAMPTZ NOT NULL,
    confidence INTEGER NOT NULL CHECK (confidence >= 0 AND confidence <= 100),
    hashed_from_ip TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 共有トークンテーブル
CREATE TABLE shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    token TEXT UNIQUE NOT NULL,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- インデックス作成
CREATE INDEX idx_users_handle ON users(handle);
CREATE INDEX idx_routes_owner_id ON routes(owner_id);
CREATE INDEX idx_routes_visibility ON routes(visibility);
CREATE INDEX idx_routes_tags ON routes USING GIN(tags);
CREATE INDEX idx_routes_geom ON routes USING GIST(geom);
CREATE INDEX idx_waypoints_route_id ON waypoints(route_id);
CREATE INDEX idx_waypoints_seq ON waypoints(route_id, seq);
CREATE INDEX idx_spots_geom ON spots USING GIST(geom);
CREATE INDEX idx_spots_tags ON spots USING GIN(tags);
CREATE INDEX idx_yae_events_user_a ON yae_events(user_a);
CREATE INDEX idx_yae_events_user_b ON yae_events(user_b);
CREATE INDEX idx_yae_events_happened_at ON yae_events(happened_at);
CREATE INDEX idx_shares_token ON shares(token);
CREATE INDEX idx_shares_route_id ON shares(route_id);

-- 更新日時の自動更新トリガー
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_routes_updated_at BEFORE UPDATE ON routes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- サンプルデータの挿入
INSERT INTO users (handle, display_name, privacy_level) VALUES
    ('test_user', 'テストユーザー', 'standard'),
    ('demo_rider', 'デモライダー', 'open');

-- サンプルルート（東京駅周辺）
INSERT INTO routes (owner_id, title, description, geom, distance_m, tags, visibility) VALUES
    (
        (SELECT id FROM users WHERE handle = 'test_user'),
        '東京駅周辺ツーリング',
        '東京駅から皇居周辺を回る短距離ルート',
        ST_GeomFromText('MULTILINESTRING((139.7673 35.6812, 139.7683 35.6822, 139.7693 35.6832))', 4326),
        5000,
        ARRAY['scenic', 'food'],
        'public'
    );

-- サンプルウェイポイント
INSERT INTO waypoints (route_id, seq, name, desc, geom) VALUES
    (
        (SELECT id FROM routes WHERE title = '東京駅周辺ツーリング'),
        1,
        'スタート地点',
        '東京駅前',
        ST_GeomFromText('POINT(139.7673 35.6812)', 4326)
    ),
    (
        (SELECT id FROM routes WHERE title = '東京駅周辺ツーリング'),
        2,
        'ゴール地点',
        '皇居前',
        ST_GeomFromText('POINT(139.7693 35.6832)', 4326)
    );

-- サンプルスポット
INSERT INTO spots (geom, name, tags, verified) VALUES
    (
        ST_GeomFromText('POINT(139.7673 35.6812)', 4326),
        '東京駅前駐車場',
        ARRAY['parking2w'],
        TRUE
    ),
    (
        ST_GeomFromText('POINT(139.7683 35.6822)', 4326),
        '皇居前カフェ',
        ARRAY['food', 'rider_welcome'],
        FALSE
    );
