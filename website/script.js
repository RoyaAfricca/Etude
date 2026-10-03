document.addEventListener('DOMContentLoaded', () => {

    // ── Particle Canvas ──────────────────────────────────────────────────────
    const canvas = document.getElementById('particles-canvas');
    const ctx = canvas.getContext('2d');
    let particles = [];

    function resizeCanvas() {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
    }
    resizeCanvas();
    window.addEventListener('resize', () => { resizeCanvas(); initParticles(); });

    function initParticles() {
        particles = [];
        const count = Math.floor((canvas.width * canvas.height) / 18000);
        for (let i = 0; i < count; i++) {
            particles.push({
                x: Math.random() * canvas.width,
                y: Math.random() * canvas.height,
                r: Math.random() * 1.5 + 0.3,
                dx: (Math.random() - 0.5) * 0.4,
                dy: (Math.random() - 0.5) * 0.4,
                alpha: Math.random() * 0.5 + 0.1
            });
        }
    }
    initParticles();

    function drawParticles() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        particles.forEach(p => {
            ctx.beginPath();
            ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
            ctx.fillStyle = `rgba(139, 92, 246, ${p.alpha})`;
            ctx.fill();
            p.x += p.dx;
            p.y += p.dy;
            if (p.x < 0 || p.x > canvas.width) p.dx *= -1;
            if (p.y < 0 || p.y > canvas.height) p.dy *= -1;
        });
        // Draw connections
        particles.forEach((p1, i) => {
            particles.slice(i + 1).forEach(p2 => {
                const dist = Math.hypot(p1.x - p2.x, p1.y - p2.y);
                if (dist < 120) {
                    ctx.beginPath();
                    ctx.moveTo(p1.x, p1.y);
                    ctx.lineTo(p2.x, p2.y);
                    ctx.strokeStyle = `rgba(139, 92, 246, ${0.06 * (1 - dist / 120)})`;
                    ctx.lineWidth = 0.5;
                    ctx.stroke();
                }
            });
        });
        requestAnimationFrame(drawParticles);
    }
    drawParticles();

    // ── Typing Effect ─────────────────────────────────────────────────────────
    const words = ['Étude', 'Précision', 'Simplicité', 'Efficacité'];
    const typingEl = document.getElementById('typing-text');
    let wordIdx = 0, charIdx = 0, deleting = false;

    function typeWriter() {
        if (!typingEl) return;
        const word = words[wordIdx];
        if (!deleting) {
            typingEl.textContent = word.slice(0, charIdx + 1);
            charIdx++;
            if (charIdx === word.length) {
                deleting = true;
                setTimeout(typeWriter, 2000);
                return;
            }
        } else {
            typingEl.textContent = word.slice(0, charIdx - 1);
            charIdx--;
            if (charIdx === 0) {
                deleting = false;
                wordIdx = (wordIdx + 1) % words.length;
            }
        }
        setTimeout(typeWriter, deleting ? 60 : 90);
    }
    typeWriter();

    // ── Intersection Observer (Fade-in + Fly-in + Counters) ──────────────────
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                // Start counter if needed
                if (entry.target.classList.contains('stat-counter')) {
                    entry.target.querySelectorAll('.counter').forEach(animateCounter);
                }
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.15 });

    document.querySelectorAll('.fade-in, .fly-in').forEach(el => observer.observe(el));
    document.querySelectorAll('.stat-counter').forEach(el => observer.observe(el));

    // ── Counter Animation ─────────────────────────────────────────────────────
    function animateCounter(el) {
        const target = parseInt(el.getAttribute('data-target'), 10);
        const duration = 1800;
        const start = performance.now();
        function step(now) {
            const elapsed = now - start;
            const progress = Math.min(elapsed / duration, 1);
            const eased = 1 - Math.pow(1 - progress, 4); // ease-out-quart
            el.textContent = Math.floor(eased * target);
            if (progress < 1) requestAnimationFrame(step);
            else el.textContent = target;
        }
        requestAnimationFrame(step);
    }

    // ── Tilt Effect ───────────────────────────────────────────────────────────
    document.querySelectorAll('.tilt-effect').forEach(el => {
        el.addEventListener('mousemove', (e) => {
            const rect = el.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            const cx = rect.width / 2, cy = rect.height / 2;
            const rx = ((y - cy) / cy) * -8;
            const ry = ((x - cx) / cx) * 8;
            el.style.transform = `perspective(1000px) rotateX(${rx}deg) rotateY(${ry}deg) scale3d(1.03, 1.03, 1.03)`;
        });
        el.addEventListener('mouseleave', () => {
            el.style.transition = 'transform 0.5s ease';
            el.style.transform = 'perspective(1000px) rotateX(0) rotateY(0) scale3d(1,1,1)';
        });
        el.addEventListener('mouseenter', () => { el.style.transition = 'none'; });
    });

    // ── Navbar scroll effect ──────────────────────────────────────────────────
    const navbar = document.querySelector('.navbar');
    window.addEventListener('scroll', () => {
        if (window.scrollY > 60) {
            navbar.style.background = 'rgba(8,12,26,0.85)';
            navbar.style.boxShadow = '0 12px 40px rgba(0,0,0,0.5)';
        } else {
            navbar.style.background = 'var(--glass-bg)';
            navbar.style.boxShadow = '0 8px 32px rgba(0,0,0,0.3)';
        }
    });

    // ── Hamburger / Mobile Menu ───────────────────────────────────────────────
    const hamburger = document.getElementById('hamburger');
    const mobileMenu = document.getElementById('mobileMenu');
    hamburger?.addEventListener('click', () => {
        mobileMenu.classList.toggle('open');
    });
    mobileMenu?.querySelectorAll('a').forEach(link => {
        link.addEventListener('click', () => mobileMenu.classList.remove('open'));
    });

    // ── Smooth Scroll ─────────────────────────────────────────────────────────
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            const targetId = this.getAttribute('href');
            if (targetId === '#') return;
            e.preventDefault();
            const target = document.querySelector(targetId);
            if (target) target.scrollIntoView({ behavior: 'smooth' });
        });
    });

    // ── Phone Mockup Slider ───────────────────────────────────────────────────
    const screens = document.querySelectorAll('.mockup-screen');
    if (screens.length > 0) {
        let currentScreen = 0;
        setInterval(() => {
            screens[currentScreen].classList.remove('active');
            currentScreen = (currentScreen + 1) % screens.length;
            screens[currentScreen].classList.add('active');

            // Re-trigger mini-bars animation if the dashboard is shown
            if (currentScreen === 0) {
                const miniBars = document.querySelectorAll('.mini-bar');
                miniBars.forEach(bar => { bar.style.opacity = '0'; bar.style.transition = 'none'; });
                setTimeout(() => {
                    miniBars.forEach((bar, i) => {
                        bar.style.transition = `height 0.6s ease ${i * 0.08}s, opacity 0.4s ease ${i * 0.08}s`;
                        setTimeout(() => { bar.style.opacity = '1'; }, 50);
                    });
                }, 50);
            }
        }, 3500); // Change screen every 3.5 seconds
    }

    // Initial Mini bars animated fill
    setTimeout(() => {
        document.querySelectorAll('.mini-bar').forEach((bar, i) => {
            bar.style.opacity = '0';
            bar.style.transition = `height 0.6s ease ${i * 0.08}s, opacity 0.4s ease ${i * 0.08}s`;
            setTimeout(() => { bar.style.opacity = '1'; }, 200 + i * 80);
        });
    }, 500);

    // ── GitHub Releases Dynamic Loader ─────────────────────────────────────────
    const repo = 'RoyaAfricca/Etude';
    
    function formatDate(dateString) {
        try {
            const date = new Date(dateString);
            return 'le ' + date.toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' });
        } catch (e) {
            return '';
        }
    }

    function parseMarkdown(md) {
        if (!md) return '';
        let html = md;
        
        // Échapper le HTML pour éviter les failles XSS
        html = html.replace(/&/g, '&amp;')
                   .replace(/</g, '&lt;')
                   .replace(/>/g, '&gt;');

        // Titres
        html = html.replace(/^## (.*?)$/gm, '<h4 class="changelog-title" style="margin-top: 15px; margin-bottom: 8px; color: #fff; font-weight: 600;">$1</h4>');
        html = html.replace(/^### (.*?)$/gm, '<h5 class="changelog-subtitle" style="margin-top: 12px; margin-bottom: 6px; color: #a78bfa;">$1</h5>');

        // Gras et Italique
        html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
        html = html.replace(/\*(.*?)\*/g, '<em>$1</em>');

        // Listes à puces
        let inList = false;
        const lines = html.split('\n');
        const formattedLines = lines.map(line => {
            const match = line.match(/^[\*\-]\s*(.*?)$/);
            if (match) {
                let li = `<li style="margin-bottom: 6px; color: var(--text-muted);">${match[1]}</li>`;
                if (!inList) {
                    inList = true;
                    li = `<ul class="changelog-list" style="margin-left: 20px; margin-bottom: 14px; list-style-type: disc;">${li}`;
                }
                return li;
            } else {
                if (inList) {
                    inList = false;
                    return `</ul>${line}`;
                }
                return line;
            }
        });
        if (inList) {
            formattedLines.push('</ul>');
        }
        html = formattedLines.join('\n');

        // Sauts de ligne
        html = html.replace(/\n\n/g, '<br>');
        
        return html;
    }

    async function loadGitHubRelease() {
        try {
            const response = await fetch(`https://api.github.com/repos/${repo}/releases/latest`);
            if (!response.ok) throw new Error('API request failed');
            
            const release = await response.json();
            const version = release.tag_name;
            const body = release.body;
            const dateStr = formatDate(release.published_at);
            
            // Recherche des assets APK et EXE
            let apkUrl = null;
            let exeUrl = null;
            
            if (release.assets && Array.isArray(release.assets)) {
                release.assets.forEach(asset => {
                    if (asset.name.endsWith('.apk')) {
                        apkUrl = asset.browser_download_url;
                    } else if (asset.name.endsWith('.exe')) {
                        exeUrl = asset.browser_download_url;
                    }
                });
            }
            
            // Mise à jour de l'affichage
            if (version) {
                const heroVer = document.getElementById('hero-version-text');
                if (heroVer) heroVer.textContent = version;
                
                const dlVer = document.getElementById('download-version-text');
                if (dlVer) dlVer.textContent = version;
                
                const changelogVer = document.getElementById('changelog-version');
                if (changelogVer) changelogVer.textContent = version;
            }
            
            if (dateStr) {
                const dlDate = document.getElementById('download-date-text');
                if (dlDate) dlDate.textContent = `(publiée ${dateStr}) `;
            }
            
            if (apkUrl) {
                const apkBtn = document.getElementById('download-android-standard');
                if (apkBtn) apkBtn.href = apkUrl;
                
                const huaweiBtn = document.getElementById('download-android-huawei');
                if (huaweiBtn) huaweiBtn.href = apkUrl;
            }
            
            if (exeUrl) {
                const exeBtn = document.getElementById('download-windows-exe');
                if (exeBtn) exeBtn.href = exeUrl;
            }
            
            if (body) {
                const changelogContent = document.getElementById('changelog-content');
                const changelogContainer = document.getElementById('changelog-container');
                if (changelogContent && changelogContainer) {
                    changelogContent.innerHTML = parseMarkdown(body);
                    changelogContainer.style.display = 'block';
                    
                    // Ré-observer si l'Intersection Observer est disponible
                    if (typeof observer !== 'undefined') {
                        observer.observe(changelogContainer);
                    }
                }
            }
        } catch (error) {
            console.warn('Impossible de charger la release GitHub, repli sur les fichiers locaux:', error);
        }
    }
    loadGitHubRelease();

});
