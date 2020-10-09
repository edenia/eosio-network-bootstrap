class ValidationRuleError extends Error {
  constructor(payload = {}, ...params) {
    super(...params)

    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, ValidationRuleError)
    }

    this.name = 'ValidationRuleError'
    this.payload = payload
  }
}

const getStandardError = (error) => {
  if (error instanceof ValidationRuleError) {
    return error.payload
  }

  if (error.isAxiosError && error.response) {
    return error.response.data
  }

  return {
    code: 500,
    message: 'Internal Service Error',
    error: {
      code: 515193181,
      name: 'unexpected_exception',
      what: `Unexpected exception ${error.message}`,
      details: [
        {
          message: error.message
        }
      ]
    }
  }
}

module.exports = {
  ValidationRuleError,
  getStandardError
}
