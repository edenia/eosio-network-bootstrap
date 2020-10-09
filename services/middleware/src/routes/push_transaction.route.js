const axios = require('axios').default
const { Api, JsonRpc } = require('eosjs')
const { JsSignatureProvider } = require('eosjs/dist/eosjs-jssig')
const fetch = require('node-fetch')
const { TextEncoder, TextDecoder } = require('util')

const { eosConfig } = require('../config')
const { errorUtil, rulesUtil } = require('../utils')

const textEncoder = new TextEncoder()
const textDecoder = new TextDecoder()
const rpc = new JsonRpc(eosConfig.apiEndpoint, { fetch })
const api = new Api({
  rpc,
  textDecoder,
  textEncoder,
  chainId: eosConfig.chainId,
  authorityProvider: {
    getRequiredKeys: () => {
      // TODO: get pubKey from vault
      return Promise.resolve([eosConfig.writer.pubKey])
    }
  },
  // TODO: get privateKey from vault
  signatureProvider: new JsSignatureProvider([eosConfig.writer.privateKey])
})

module.exports = {
  method: 'POST',
  path: '/v1/chain/push_transaction',
  handler: async (req, h) => {
    try {
      console.log('push_transaction', 'middleware')
      const originalPayload = JSON.parse(req.payload)
      const orinalTransation = await api.deserializeTransactionWithActions(originalPayload.packed_trx)
      rulesUtil.validateTransction(orinalTransation)
      const localTransaction = await api.transact(orinalTransation, { broadcast: false })
      let payload = originalPayload

      if (localTransaction.signatures[0] !== originalPayload.signatures[0]) {
        payload = {
          compression: originalPayload.compression,
          packed_context_free_data: originalPayload.packed_context_free_data,
          packed_trx: originalPayload.packed_trx,
          signatures: [...localTransaction.signatures, ...originalPayload.signatures]
        }
      }

      const { data } = await axios.post(`${eosConfig.apiEndpoint}/v1/chain/push_transaction`, JSON.stringify(payload))

      return data
    } catch (error) {
      const standardError = errorUtil.getStandardError(error)

      return h.response(standardError).code(standardError.code)
    }
  }
}
