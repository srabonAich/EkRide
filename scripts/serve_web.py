import sys
import os
import functools
from http.server import HTTPServer, SimpleHTTPRequestHandler

class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

    def do_GET(self):
        # SPA routing fallback: if path doesn't exist and has no extension, serve index.html
        path = self.translate_path(self.path)
        if not os.path.exists(path) and '.' not in os.path.basename(self.path):
            self.path = '/index.html'
        return super().do_GET()

def main():
    # Dynamically determine the web build directory relative to this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = os.path.dirname(script_dir)
    directory = os.path.join(base_dir, "frontend", "build", "web")
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 3000

    if not os.path.isdir(directory):
        print(f"Warning: Flutter web build directory not found at '{directory}'.", file=sys.stderr)
        print("Please build Flutter web first: (cd frontend && flutter build web)", file=sys.stderr)
        print("Or run Flutter directly in development mode: (cd frontend && flutter run -d chrome --web-port=3000)", file=sys.stderr)

    NoCacheHandler.extensions_map.update({
        '.js': 'application/javascript',
        '.wasm': 'application/wasm',
        '.json': 'application/json',
    })
    handler = functools.partial(NoCacheHandler, directory=directory)
    server = HTTPServer(('0.0.0.0', port), handler)
    print(f"EkRide Frontend Server running at http://localhost:{port} (Cache disabled)", flush=True)
    server.serve_forever()

if __name__ == '__main__':
    main()
