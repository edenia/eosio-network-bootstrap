const getAccountRoute = require('./get-account.route')
const getInfoRoute = require('./get-info.route')
const getRequiredKeysRoute = require('./get-required-keys.route')
const healthzRoute = require('./healthz.route')
const proxyRoute = require('./proxy.route')
const pushTransactionRoute = require('./push_transaction.route')

module.exports = [getAccountRoute, getInfoRoute, getRequiredKeysRoute, healthzRoute, proxyRoute, pushTransactionRoute]
