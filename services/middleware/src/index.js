const Hapi = require('@hapi/hapi')
const routes = require('./routes')

const init = async () => {
  const server = Hapi.server({
    port: '4200',
    host: '0.0.0.0',
    routes: {
      cors: { origin: ['*'] }
    }
  })
  server.route(routes)
  await server.start()

  console.log(`🚀 Server ready at ${server.info.uri}`)
  server.table().forEach((route) => console.log(`${route.method}\t${route.path}`))
}

init()
