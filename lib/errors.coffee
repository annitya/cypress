_       = require("lodash")
chalk   = require("chalk")
ansi_up = require("ansi_up")
Promise = require("bluebird")

exceptions = "CI_CANNOT_COMMUNICATE".split(" ")

API = {
  getMsgByType: (type, arg1, arg2) ->
    switch type
      when "NOT_LOGGED_IN"
        "Can't fulfill request without authorization. \nLog into Cypress and issue the command again."
      when "TESTS_DID_NOT_START"
        "Can't start tests, the remote client never connected."
      when "PROJECT_DOES_NOT_EXIST"
        "Can't find project. Add project to Cypress."
      when "NOT_CI_ENVIRONMENT"
        "Can't run CI outside of a CI provider and environment"
      when "CI_KEY_NOT_VALID"
        "Can't run project in CI. Your project's CI Key, #{chalk.blue(arg1)}, is invalid."
      when "CI_CANNOT_COMMUNICATE"
        "Can't communicate with remote Cypress servers. This is a temporarily problem. Try again later."
      when "DEV_NO_SERVER"
        " > The local API server isn't running in development. This may cause problems running the GUI."
      when "NO_PROJECT_ID"
        "Can't find 'projectId' in the 'cypress.json' file for this project: " + chalk.blue(arg1)
      when "NO_PROJECT_FOUND_AT_PROJECT_ROOT"
        "Can't find project at the path: " + chalk.blue(arg1)
      when "CANNOT_FETCH_PROJECT_TOKEN"
        "Can't find project's secret key."
      when "CANNOT_CREATE_PROJECT_TOKEN"
        "Can't create project's secret key."
      when "PORT_IN_USE_SHORT"
        "Port '#{arg1}' is already in use."
      when "PORT_IN_USE_LONG"
        "Can't run project because port is currently in use: " + chalk.blue(arg1) + "\n\n" + chalk.yellow("Assign a different port with the '--port <port>' argument or shut down the other running process.")
      when "ERROR_READING_FILE"
        "Error reading from: " + chalk.blue(arg1) + "\n\n" + chalk.yellow(arg2)
      when "ERROR_WRITING_FILE"
        "Error writing to: " + chalk.blue(arg1) + "\n\n" + chalk.yellow(arg2)
      when "SPEC_FILE_NOT_FOUND"
        "Can't find test spec " + chalk.blue(arg1)
      when "NO_CURRENTLY_OPEN_PROJECT"
        "Can't find open project."

  get: (type, arg1, arg2) ->
    msg = @getMsgByType(type, arg1, arg2)
    err = new Error(msg)
    err.type = type
    err

  isCypressErr: (err) ->
    ## if we have a type
    err.type and

      ## and its found in our list of errors
      @getMsgByType(err.type) and

        ## and its not an exception
        err.type not in exceptions

  warning: (type) ->
    err = @get(type)
    @log(err, "magenta")

  log: (err, color = "red") ->
    Promise.try =>
      console.log chalk[color](err.message)

      ## bail if this error came from known
      ## list of Cypress errors
      return if @isCypressErr(err)

      ## else either log the error in raygun
      ## or log the stack trace in dev mode
      switch process.env["CYPRESS_ENV"]
        when "production"
          ## log this to raygun
        else
          ## write stack out to console
          console.log(err.stack)

  throw: (type, arg) ->
    throw @get(type, arg)

  clone: (err) ->
    ## pull off these properties
    obj = _.pick(err, "type", "name", "stack", "fileName", "lineNumber", "columnNumber")

    obj.message = ansi_up.ansi_to_html(err.message, {
      use_classes: true
    })

    ## and any own (custom) properties
    ## of the err object
    for own prop, val of err
      obj[prop] = val

    obj
}

module.exports = _.bindAll(API)