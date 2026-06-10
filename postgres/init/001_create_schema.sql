-- =========================================
-- Schéma de base de données e-commerce pour chatbot
-- =========================================

-- Table des clients
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20)
);

-- Table des produits
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0
);

-- Table des commandes
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    order_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending'
);

-- Table de liaison commandes-produits
CREATE TABLE order_products (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL DEFAULT 1
);

-- Table des livraisons
CREATE TABLE shipping (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id),
    address TEXT NOT NULL,
    delivery_status VARCHAR(50) NOT NULL DEFAULT 'label_created',
    delivery_date DATE
);

-- Table des retours
CREATE TABLE returns (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    return_date DATE NOT NULL,
    return_status VARCHAR(50) NOT NULL DEFAULT 'requested',
    refund_amount DECIMAL(10,2)
);

-- Table des tickets de support
CREATE TABLE support_tickets (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    ticket_date DATE NOT NULL,
    subject VARCHAR(255) NOT NULL,
    description TEXT,
    ticket_status VARCHAR(50) NOT NULL DEFAULT 'open'
);

-- Table des promotions
CREATE TABLE promotions (
    id SERIAL PRIMARY KEY,
    promo_code VARCHAR(50) UNIQUE NOT NULL,
    product_id INTEGER REFERENCES products(id),
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    discount_percent DECIMAL(5,2) NOT NULL
);

-- =========================================
-- Tables pour le système de chat
-- =========================================

-- Table des sessions de chat
CREATE TABLE chat_sessions (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    external_session_id VARCHAR(255),
    channel VARCHAR(50) NOT NULL DEFAULT 'web',
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    metadata JSONB
);

-- Table des messages de chat
CREATE TABLE chat_messages (
    id SERIAL PRIMARY KEY,
    session_id INTEGER NOT NULL REFERENCES chat_sessions(id),
    role VARCHAR(20) NOT NULL, -- 'user', 'assistant', 'system'
    content TEXT NOT NULL,
    message_index INTEGER NOT NULL,
    model_name VARCHAR(100),
    tool_calls JSONB,
    metadata JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(session_id, message_index)
);

-- =========================================
-- Index pour optimiser les performances
-- =========================================

CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_order_products_order_id ON order_products(order_id);
CREATE INDEX idx_order_products_product_id ON order_products(product_id);
CREATE INDEX idx_shipping_order_id ON shipping(order_id);
CREATE INDEX idx_returns_order_id ON returns(order_id);
CREATE INDEX idx_support_tickets_customer_id ON support_tickets(customer_id);
CREATE INDEX idx_promotions_code ON promotions(promo_code);
CREATE INDEX idx_promotions_dates ON promotions(start_date, end_date);

CREATE INDEX idx_chat_sessions_customer_id ON chat_sessions(customer_id);
CREATE INDEX idx_chat_sessions_external_id ON chat_sessions(external_session_id);
CREATE INDEX idx_chat_messages_session_id ON chat_messages(session_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at);

-- =========================================
-- Contraintes supplémentaires
-- =========================================

ALTER TABLE orders ADD CONSTRAINT chk_order_status
    CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'));

ALTER TABLE shipping ADD CONSTRAINT chk_delivery_status
    CHECK (delivery_status IN ('label_created', 'in_transit', 'out_for_delivery', 'delivered', 'delayed'));

ALTER TABLE returns ADD CONSTRAINT chk_return_status
    CHECK (return_status IN ('requested', 'approved', 'rejected', 'refunded'));

ALTER TABLE support_tickets ADD CONSTRAINT chk_ticket_status
    CHECK (ticket_status IN ('open', 'in_progress', 'resolved', 'closed'));

ALTER TABLE chat_sessions ADD CONSTRAINT chk_session_status
    CHECK (status IN ('active', 'ended'));

ALTER TABLE chat_messages ADD CONSTRAINT chk_message_role
    CHECK (role IN ('user', 'assistant', 'system'));

-- =========================================
-- Commentaires pour documentation
-- =========================================

COMMENT ON TABLE customers IS 'Informations des clients de l''e-commerce';
COMMENT ON TABLE products IS 'Catalogue des produits avec stock et prix';
COMMENT ON TABLE orders IS 'Commandes passées par les clients';
COMMENT ON TABLE order_products IS 'Détail des produits dans chaque commande';
COMMENT ON TABLE shipping IS 'Informations de livraison des commandes';
COMMENT ON TABLE returns IS 'Demandes de retour et remboursements';
COMMENT ON TABLE support_tickets IS 'Tickets de support client';
COMMENT ON TABLE promotions IS 'Codes promotionnels et offres spéciales';
COMMENT ON TABLE chat_sessions IS 'Sessions de conversation avec le chatbot';
COMMENT ON TABLE chat_messages IS 'Messages échangés dans les sessions de chat';