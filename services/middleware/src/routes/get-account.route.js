const axios = require('axios').default

const { eosConfig } = require('../config')
const { errorUtil } = require('../utils')

module.exports = {
  method: 'POST',
  path: '/v1/chain/get_account',
  handler: async (req, h) => {
    try {
      console.log('get_account', 'middleware')
      const { data } = await axios.post(`${eosConfig.apiEndpoint}/v1/chain/get_account`, req.payload)

      // TODO: add comment to clarify kyes usage
      return {
        ...data,
        permissions: data.permissions.map((permission) => {
          return {
            ...permission,
            required_auth: {
              ...permission.required_auth,
              threshold: 1
            }
          }
        })
      }
    } catch (error) {
      const standardError = errorUtil.getStandardError(error)

      return h.response(standardError).code(standardError.code)
    }
  }
}
