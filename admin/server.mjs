import { createReadStream, existsSync, statSync } from 'node:fs'
import { createServer } from 'node:http'
import { extname, join, normalize } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = fileURLToPath(new URL('.', import.meta.url))
const host = '127.0.0.1'
const port = Number(process.env.IC_CARD_ADMIN_PORT ?? 4173)
const mimeTypes = new Map([
  ['.css', 'text/css; charset=utf-8'],
  ['.html', 'text/html; charset=utf-8'],
  ['.js', 'text/javascript; charset=utf-8'],
  ['.mjs', 'text/javascript; charset=utf-8'],
  ['.svg', 'image/svg+xml'],
])

createServer((request, response) => {
  const url = new URL(request.url ?? '/', `http://${host}:${port}`)
  const requestedPath = url.pathname === '/' ? '/index.html' : url.pathname
  const relativePath = normalize(decodeURIComponent(requestedPath)).replace(
    /^(\.\.(\\|\/|$))+/,
    '',
  )
  const filePath = join(root, relativePath)
  if (!filePath.startsWith(root) || !existsSync(filePath) || !statSync(filePath).isFile()) {
    response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' })
    response.end('Not found')
    return
  }

  response.writeHead(200, {
    'Content-Type': mimeTypes.get(extname(filePath)) ?? 'application/octet-stream',
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Referrer-Policy': 'no-referrer',
    'Content-Security-Policy':
      "default-src 'self'; connect-src 'self' https://uenyouholkxxyyaukrbz.supabase.co; style-src 'self'; script-src 'self'; img-src 'self' data:; frame-ancestors 'none'",
  })
  createReadStream(filePath).pipe(response)
}).listen(port, host, () => {
  console.log(`IC 카드 문의 관리: http://${host}:${port}`)
  console.log('종료하려면 Ctrl+C를 누르세요.')
})
