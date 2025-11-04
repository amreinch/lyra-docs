# Lyra Documentation

Professional documentation site for Lyra Platform built with MkDocs and Material theme.

## Overview

This repository contains the complete documentation for Lyra Platform, including:

- **Installation Guide**: Step-by-step deployment instructions
- **Administration Guide**: System configuration and management
- **User Guide**: End-user documentation
- **API Reference**: Complete REST API documentation
- **Troubleshooting**: Common issues and solutions

## Technology Stack

- **MkDocs**: Static site generator
- **Material for MkDocs**: Professional theme
- **Python**: Build environment
- **Nginx/Apache**: Web server hosting

## Project Structure

```
lyra-docs/
├── docs/                      # Documentation source files
│   ├── index.md              # Homepage
│   ├── installation/         # Installation guides
│   ├── admin/                # Administration guides
│   ├── user/                 # User guides
│   ├── api/                  # API reference
│   ├── troubleshooting/      # Troubleshooting guides
│   ├── development/          # Development docs
│   ├── assets/               # Images, logos, etc.
│   ├── stylesheets/          # Custom CSS
│   └── javascripts/          # Custom JavaScript
├── site/                     # Generated static site (after build)
├── mkdocs.yml                # MkDocs configuration
├── requirements.txt          # Python dependencies
├── nginx.conf                # Nginx configuration example
├── apache.conf               # Apache configuration example
├── build.sh                  # Build script
├── deploy.sh                 # Deployment script
└── README.md                 # This file
```

## Quick Start

### Local Development

1. **Install dependencies**:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Start development server**:
   ```bash
   mkdocs serve
   ```

3. **View documentation**:
   Open [http://localhost:8000](http://localhost:8000) in your browser

### Build for Production

Build the static site:

```bash
./build.sh
```

This generates static HTML files in the `site/` directory.

### Deploy to Web Server

Deploy to your Nginx/Apache server:

```bash
# Basic deployment
./deploy.sh --server docs.lyra.ovh --user ubuntu

# With custom path and SSH key
./deploy.sh --server docs.lyra.ovh --user ubuntu --path /var/www/lyra-docs --key ~/.ssh/id_rsa
```

#### Deployment Options

- `-s, --server SERVER`: Web server address (required)
- `-u, --user USER`: SSH user (default: www-data)
- `-p, --path PATH`: Deployment path (default: /var/www/lyra-docs)
- `-k, --key KEY`: SSH private key file
- `-h, --help`: Show help message

## Web Server Configuration

### Nginx

1. **Copy configuration**:
   ```bash
   sudo cp nginx.conf /etc/nginx/sites-available/lyra-docs
   ```

2. **Update paths** in `/etc/nginx/sites-available/lyra-docs`:
   - SSL certificate paths
   - Document root path
   - Server name

3. **Enable site**:
   ```bash
   sudo ln -s /etc/nginx/sites-available/lyra-docs /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```

### Apache

1. **Enable required modules**:
   ```bash
   sudo a2enmod ssl rewrite headers deflate
   ```

2. **Copy configuration**:
   ```bash
   sudo cp apache.conf /etc/apache2/sites-available/lyra-docs.conf
   ```

3. **Update paths** in `/etc/apache2/sites-available/lyra-docs.conf`:
   - SSL certificate paths
   - Document root path
   - Server name

4. **Enable site**:
   ```bash
   sudo a2ensite lyra-docs
   sudo apache2ctl configtest
   sudo systemctl reload apache2
   ```

## Writing Documentation

### Adding New Pages

1. Create a new `.md` file in the appropriate directory under `docs/`
2. Add the page to navigation in `mkdocs.yml`
3. Write content using Markdown

### Markdown Features

#### Admonitions (Info Boxes)

```markdown
!!! note "Optional Title"
    This is a note

!!! warning
    This is a warning

!!! danger
    This is a danger alert

!!! tip
    This is a helpful tip
```

#### Code Blocks

````markdown
```python
def hello():
    print("Hello, World!")
```

```bash
kubectl get pods
```
````

#### Tables

```markdown
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Value 1  | Value 2  | Value 3  |
```

#### Images

```markdown
![Alt text](assets/image.png)
```

#### Links

```markdown
[Link text](other-page.md)
[External link](https://example.com)
```

### Adding Images

1. Place images in `docs/assets/` or subdirectories
2. Reference in markdown: `![Description](assets/image.png)`
3. Images automatically open in lightbox (glightbox plugin)

### Custom Styling

- Custom CSS: Add to `docs/stylesheets/extra.css`
- Custom JavaScript: Add to `docs/javascripts/extra.js`

## Material Theme Features

### Content Tabs

```markdown
=== "Tab 1"
    Content for tab 1

=== "Tab 2"
    Content for tab 2
```

### Grid Cards

```markdown
<div class="grid cards" markdown>

-   :material-clock-fast:{ .lg .middle } __Feature 1__

    ---

    Description of feature 1

-   :material-check:{ .lg .middle } __Feature 2__

    ---

    Description of feature 2

</div>
```

### Icons

Use Material Design icons:

```markdown
:material-account: User icon
:material-check: Check icon
:octicons-alert-16: Alert icon
```

Browse icons: [Material Icons](https://squidfunk.github.io/mkdocs-material/reference/icons-emojis/)

## Maintenance

### Update Dependencies

```bash
source venv/bin/activate
pip install --upgrade -r requirements.txt
```

### Clean Build

```bash
mkdocs build --clean
```

### Validate Links

```bash
# Install link checker (optional)
pip install mkdocs-linkcheck
mkdocs build
```

## Continuous Deployment

For automated deployments, integrate with CI/CD:

```yaml
# Example GitHub Actions workflow
name: Deploy Documentation

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.x'
      - run: pip install -r requirements.txt
      - run: mkdocs build
      - name: Deploy
        run: ./deploy.sh --server ${{ secrets.WEB_SERVER }} --user ${{ secrets.WEB_USER }}
```

## Troubleshooting

### Build Errors

**Issue**: `mkdocs: command not found`

**Solution**: Activate virtual environment
```bash
source venv/bin/activate
```

**Issue**: Missing dependencies

**Solution**: Reinstall requirements
```bash
pip install -r requirements.txt
```

### Deployment Issues

**Issue**: Permission denied on web server

**Solution**: Ensure SSH user has sudo privileges or deploy to user-owned directory

**Issue**: SSL certificate errors

**Solution**: Update certificate paths in nginx.conf or apache.conf

## License

[Add your license information here]

## Support

For questions or issues with the documentation:
- Open an issue in the repository
- Contact the Lyra team

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with `mkdocs serve`
5. Submit a pull request
