const axios = require('axios').default

const { eosConfig } = require('../config')
const { errorUtil } = require('../utils')

module.exports = {
  method: 'POST',
  path: '/v1/chain/{path*}',
  handler: async (req, h) => {
    try {
      console.log(req.params.path, 'proxy')
      const { data } = await axios.post(`${eosConfig.apiEndpoint}/v1/chain/${req.params.path}`, req.payload || {})

      return data
    } catch (error) {
      const standardError = errorUtil.getStandardError(error)

      return h.response(standardError).code(standardError.code)
    }
  }
}
