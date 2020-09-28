const axios = require('axios').default

const { eosConfig } = require('../config')
const { errorUtil } = require('../utils')

module.exports = {
  method: ['GET', 'POST'],
  path: '/v1/chain/get_info',
  handler: async (req, h) => {
    try {
      console.log('get_info', 'middleware')
      const { data } = await axios.post(`${eosConfig.apiEndpoint}/v1/chain/get_info`)

      return data
    } catch (error) {
      const standardError = errorUtil.getStandardError(error)

      return h.response(standardError).code(standardError.code)
    }
  }
}
