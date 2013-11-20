window.app = angular.module('Firebrick', ['ngRoute', 'ngResource', 'ngSanitize'])
app.resolvers = {}

app.factory 'SharedData', ()-> {notification: 0, title: ""}

app.factory 'User', ($resource)->
  customActions = {update: {method: "POST"}}

  $resource(
    "/api/users/:collectionRoute:id/:memberRoute",
    { id: "@id", collectionRoute: '@collectionRoute', memberRoute: '@memberRoute'},
    customActions
  )

app.factory 'Domain', ($resource)->
  $resource(
    "/api/domains/:collectionRoute:id/:memberRoute",
    { id: "@id", collectionRoute: '@collectionRoute', memberRoute: '@memberRoute'}
  )

app.factory 'Session', ($resource)->
  $resource("/api/sessions")

app.resolvers.userSession = ($location, $q, SharedData) ->
  return true if SharedData.user
  $location.path("/login")


# TODO change this to domains. To fetch multiple domains
app.resolvers.domain = (Domain, $q, $route)->
  return {} if !$route.current.params.domain_id

  deferred = $q.defer()
  successCallback = (domain)-> deferred.resolve domain
  errorCallback   = (errorData)-> deferred.reject()

  requestParams = { id: $route.current.params.domain_id }

  Domain.get(requestParams, successCallback, errorCallback)
  deferred.promise


app.resolvers.auth = (Session, $q, $route)->

  deferred = $q.defer()
  successCallback = (session)->  deferred.resolve(session)
  errorCallback   = (response)-> deferred.reject()

  Session.get({}, successCallback, errorCallback)
  deferred.promise


# TODO need another resolver to fetch multiple users
app.resolvers.user = (User, $q, $route)->
  return {role: "member"} if !$route.current.params.user_id

  deferred = $q.defer()
  successCallback = (user)-> deferred.resolve user
  errorCallback   = (errorData)-> deferred.reject()

  requestParams = { id: $route.current.params.user_id }

  User.get(requestParams, successCallback, errorCallback)
  deferred.promise


config = ($routeProvider, $locationProvider)->
  $locationProvider.html5Mode(true)
  $routeProvider.when('/',
      templateUrl: '/static/partials/hello.html'
      controller: "MailsCtrl"
      resolve:
        userSession: app.resolvers.userSession
    ).when('/login',
      templateUrl: '/static/partials/login.html'
      controller: 'SessionCtrl'
      resolve:
        auth: app.resolvers.auth
    ).when('/labels/:label',
      templateUrl: '/static/partials/mails.html',
      controller: 'MailsCtrl'
    ).when('/domains',
      templateUrl: '/static/partials/domains.html'
      controller: 'DomainsCtrl'
      resolve:
        userSession: app.resolvers.userSession
    ).when('/users',
      templateUrl: '/static/partials/users/list.html'
      controller: 'UsersListCtrl'
      resolve:
        userSession: app.resolvers.userSession
    ).when('/users/new',
      templateUrl: '/static/partials/users/user.html'
      controller: 'UserCtrl'
      resolve:
        userSession: app.resolvers.userSession
        user: app.resolvers.user
    ).when('/users/:user_id/:edit',
      templateUrl: '/static/partials/users/user.html'
      controller: 'UserCtrl'
      resolve:
        userSession: app.resolvers.userSession
        user: app.resolvers.user
    ).otherwise(redirectTo: '/not_found')


app.config ['$routeProvider', '$locationProvider', config]


app.controller 'RootCtrl', ($scope, $location, SharedData, Session)->
  $scope.sharedData = SharedData
  $scope.logout = ->
    successCallback = (data) ->
      console.log "logging you out ~!"
      $location.path("/login")

    errorCallback = (response) =>
      console.log response.data
      #TODO handle errors

    Session.delete({}, successCallback, errorCallback)

app.controller 'SessionCtrl', ($scope, $location, SharedData, Session, auth)->
  $scope.sharedData = SharedData
  if auth.user
    $scope.sharedData.user = auth.user
    $location.path("/users")
  else
    $scope.session = {username: "whatever", password: "akash"}

  $scope.login = ->
    successCallback = (data) ->
      $location.path("/users")

    errorCallback = (response) =>
      console.log response.data
      #TODO handle errors

    Session.save($scope.session, successCallback, errorCallback)



app.controller 'MailsCtrl', ($scope, SharedData)->
  $scope.sharedData = SharedData
  $scope.sharedData.title = "Main"
  console.log $scope.sharedData
  console.log "mails controller"


app.controller 'DomainsCtrl', ($scope, SharedData, Domain)->
  $scope.sharedData = SharedData
  $scope.sharedData.title = "Domains"

  $scope.addDomain = ->
    Domain.save $scope.newDomain, (data)->
      if data["errors"]
        #TODO handle errors
      else
        $scope.domains.push($scope.newDomain)
        $scope.newDomain = {}

  #TODO do not allow deleting domain if it has users
  $scope.removeDomain = (index)->
    successCallback = -> $scope.domains.splice(index, 1)
    errorCallback = ->
      #TODO handle errors
    $scope.domains[index].$delete(successCallback, errorCallback)

  successCallback = (data)-> $scope.domains = data
  errorCallback   = ()-> console.log("error")
  Domain.query(successCallback, errorCallback)


app.controller 'UsersListCtrl', ($scope, SharedData, User)->
  $scope.sharedData = SharedData
  $scope.sharedData.title = "Users"

  $scope.removeUser = (index)->
    successCallback = -> $scope.users.splice(index, 1)
    errorCallback = ->
      #TODO handle errors
    $scope.users[index].$delete(successCallback, errorCallback)

  successCallback = (data)-> $scope.users = data
  errorCallback   = ()-> console.log("error")

  #TODO should use a resolver
  User.query(successCallback, errorCallback)


app.controller 'UserCtrl', ($scope, $route, $location, SharedData, Domain, User, user)->
  $scope.sharedData = SharedData
  #TODO should use a resolver

  domainsSuccessCallback = (data)->
    $scope.domains = data
    if !$scope.user.domain_id
      $scope.user.domain_id = $scope.domains[0].id

  domainsErrorCallback   = ()-> console.log("error")
  Domain.query(domainsSuccessCallback, domainsErrorCallback)

  if !$route.current.params.user_id
    $scope.sharedData.title = "New user"
  else
    $scope.sharedData.title = "Edit user"

  $scope.validRoles = ['admin', 'member']
  $scope.user = user

  $scope.saveUser = ->
    successCallback = (data) ->
      $location.path("/users")

    errorCallback = (response) =>
      console.log response.data
      #TODO handle errors

    if !$scope.user.id
      User.save($scope.user, successCallback, errorCallback)
    else
      user = $scope.user
      user.$update(successCallback, errorCallback)

