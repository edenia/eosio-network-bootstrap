const { ValidationRuleError } = require('./error.util')

const validateTransction = (transaction) => {
  // TODO: add new validation rules
  // TODO: first action must be from one writter and execute run action
  // TODO: at least 2 actions
  const writerActionIsPresent = !!transaction.actions.find((action) => action.account === 'writer' && action.name === 'run')

  if (!writerActionIsPresent) {
    throw new ValidationRuleError({
      code: 500,
      message: 'Internal Service Error',
      error: {
        code: 515193182,
        name: 'missing_writer_action_exception',
        what: 'Missing Writer Action "run"',
        details: [
          {
            message: 'Action "run" is required'
          }
        ]
      }
    })
  }
}

module.exports = {
  validateTransction
}
