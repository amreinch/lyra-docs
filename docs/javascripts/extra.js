// Custom JavaScript for Lyra Documentation

// Add copy button feedback
document.addEventListener('DOMContentLoaded', function() {
    // Enhance copy buttons with feedback
    document.querySelectorAll('.md-clipboard').forEach(function(button) {
        button.addEventListener('click', function() {
            const originalTitle = button.title;
            button.title = 'Copied!';
            setTimeout(function() {
                button.title = originalTitle;
            }, 2000);
        });
    });

    // Add external link indicators
    document.querySelectorAll('a[href^="http"]').forEach(function(link) {
        if (!link.hostname.includes('lyra.ovh')) {
            link.setAttribute('target', '_blank');
            link.setAttribute('rel', 'noopener noreferrer');

            // Add external link icon
            if (!link.querySelector('.external-link-icon')) {
                const icon = document.createElement('span');
                icon.className = 'external-link-icon';
                icon.innerHTML = ' ↗';
                link.appendChild(icon);
            }
        }
    });

    // Smooth scroll for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(function(anchor) {
        anchor.addEventListener('click', function(e) {
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                e.preventDefault();
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Add table wrapper for responsive tables
    document.querySelectorAll('table').forEach(function(table) {
        if (!table.parentElement.classList.contains('table-wrapper')) {
            const wrapper = document.createElement('div');
            wrapper.className = 'table-wrapper';
            table.parentNode.insertBefore(wrapper, table);
            wrapper.appendChild(table);
        }
    });

    // Back to top button (optional)
    const backToTop = document.createElement('button');
    backToTop.innerHTML = '↑';
    backToTop.className = 'back-to-top';
    backToTop.style.cssText = `
        position: fixed;
        bottom: 20px;
        right: 20px;
        display: none;
        padding: 10px 15px;
        background-color: var(--md-primary-fg-color);
        color: white;
        border: none;
        border-radius: 50%;
        cursor: pointer;
        font-size: 20px;
        z-index: 1000;
        opacity: 0.7;
        transition: opacity 0.3s;
    `;

    backToTop.addEventListener('click', function() {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });

    backToTop.addEventListener('mouseenter', function() {
        this.style.opacity = '1';
    });

    backToTop.addEventListener('mouseleave', function() {
        this.style.opacity = '0.7';
    });

    document.body.appendChild(backToTop);

    window.addEventListener('scroll', function() {
        if (window.pageYOffset > 300) {
            backToTop.style.display = 'block';
        } else {
            backToTop.style.display = 'none';
        }
    });
});

// Add print functionality
function printPage() {
    window.print();
}

// Add keyboard shortcuts
document.addEventListener('keydown', function(e) {
    // Ctrl/Cmd + P for print
    if ((e.ctrlKey || e.metaKey) && e.key === 'p') {
        e.preventDefault();
        printPage();
    }

    // Ctrl/Cmd + K for search
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        const searchInput = document.querySelector('.md-search__input');
        if (searchInput) {
            searchInput.focus();
        }
    }
});

// Analytics placeholder (add your analytics code here)
// Example: Google Analytics, Plausible, etc.
