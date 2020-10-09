const { ValidationRuleError } = require('./error.util')

const validateTransction = (transaction) => {
  // TODO: add new validation rules

  // at least 2 actions
  if (transaction.actions.length < 2) {
    throw new ValidationRuleError({
      code: 500,
      message: 'Internal Service Error',
      error: {
        code: 515193182,
        name: 'invalid_number_of_actions_exception',
        what: 'You must provide at least two actions',
        details: [
          {
            message: 'Writer action "run" an another one are required'
          }
        ]
      }
    })
  }

  // first action must be from one writter and execute run action
  if (firstTransacrtion.account !== 'writer' || firstTransacrtion.name !== 'run') {
    throw new ValidationRuleError({
      code: 500,
      message: 'Internal Service Error',
      error: {
        code: 515193183,
        name: 'invalid_writer_action_exception',
        what: 'Writer action "run" must be provided at beginning of the transaction',
        details: [
          {
            message: 'Writer action "run" is required and must be the first action in the transaction'
          }
        ]
      }
    })
  }
}

module.exports = {
  validateTransction
}
