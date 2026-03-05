#!/usr/bin/env python3
"""
Database Smoke Test for SeekReap Neon PostgreSQL
Run with: python smoke_test.py
"""

import psycopg2
import os
import sys
from datetime import datetime

# Database connection from environment or use your Neon credentials
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://neondb_owner:npg_yX7aHMwIqQC4@ep-rapid-base-ai27r1sa-pooler.c-4.us-east-1.aws.neon.tech/seekreap_neon_db?sslmode=require')

def run_health_check():
    print("=" * 50)
    print("🔍 SeekReap Database Smoke Test")
    print(f"📅 {datetime.now().isoformat()}")
    print("=" * 50)
    
    try:
        # Parse connection string or use directly
        print("\n📡 Connecting to Neon PostgreSQL...")
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        # Test 1: Basic Connection
        cur.execute("SELECT 1;")
        result = cur.fetchone()
        print(f"✅ Basic Connection: SUCCESS (got {result[0]})")
        
        # Test 2: Database Info
        cur.execute("SELECT current_database(), current_user, version();")
        db_name, db_user, version = cur.fetchone()
        print(f"✅ Database: {db_name}")
        print(f"✅ User: {db_user}")
        print(f"✅ PostgreSQL Version: {version.split()[1]}")
        
        # Test 3: Check for existing tables
        cur.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            ORDER BY table_name;
        """)
        tables = cur.fetchall()
        
        if tables:
            print(f"\n📊 Found {len(tables)} tables in 'public' schema:")
            for table in tables[:10]:  # Show first 10
                # Count rows in each table
                cur.execute(f'SELECT COUNT(*) FROM "{table[0]}";')
                count = cur.fetchone()[0]
                print(f"   • {table[0]}: {count} rows")
            if len(tables) > 10:
                print(f"   ... and {len(tables)-10} more tables")
        else:
            print("⚠️  No tables found in public schema - migrations needed?")
        
        # Test 4: Check for specific expected tables
        expected_tables = ['users', 'jobs', 'applications', 'companies']
        print("\n🔎 Checking for expected tables:")
        for table in expected_tables:
            cur.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = %s
                );
            """, (table,))
            exists = cur.fetchone()[0]
            status = "✅" if exists else "❌"
            print(f"   {status} {table}")
        
        # Test 5: Connection pool info (Neon specific)
        cur.execute("SHOW max_connections;")
        max_conn = cur.fetchone()[0]
        print(f"\n📈 Max Connections: {max_conn}")
        
        # Test 6: Simple write/read test (optional - comment out if you don't want to write)
        print("\n✍️  Testing write capability...")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS _smoke_test (
                id SERIAL PRIMARY KEY,
                test_time TIMESTAMP DEFAULT NOW(),
                test_message TEXT
            );
        """)
        cur.execute("INSERT INTO _smoke_test (test_message) VALUES (%s) RETURNING id;", 
                   (f"Smoke test at {datetime.now()}",))
        test_id = cur.fetchone()[0]
        conn.commit()
        
        cur.execute("SELECT test_message FROM _smoke_test WHERE id = %s;", (test_id,))
        message = cur.fetchone()[0]
        print(f"✅ Write/Read Test: SUCCESS (wrote and read back: '{message[:30]}...')")
        
        # Clean up
        cur.execute("DROP TABLE _smoke_test;")
        conn.commit()
        
        cur.close()
        conn.close()
        
        print("\n" + "=" * 50)
        print("✅ ALL TESTS PASSED! Database is healthy.")
        print("=" * 50)
        
    except Exception as e:
        print(f"\n❌ Smoke Test FAILED: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    run_health_check()
