const axios = require('axios').default

const { eosConfig } = require('../config')
const { errorUtil, rulesUtil } = require('../utils')

module.exports = {
  method: 'POST',
  path: '/v1/chain/get_required_keys',
  handler: async (req, h) => {
    try {
      console.log('get_required_keys', 'middleware')
      const originalPayload = JSON.parse(req.payload)
      rulesUtil.validateTransction(originalPayload.transaction)
      const payload = {
        ...originalPayload,
        available_keys: [eosConfig.writer.pubKey, ...originalPayload.available_keys]
      }
      const { data } = await axios.post(`${eosConfig.apiEndpoint}/v1/chain/get_required_keys`, JSON.stringify(payload))

      return {
        ...data,
        required_keys: data.required_keys.filter((item) => item !== eosConfig.writer.pubKey)
      }
    } catch (error) {
      const standardError = errorUtil.getStandardError(error)

      return h.response(standardError).code(standardError.code)
    }
  }
}
