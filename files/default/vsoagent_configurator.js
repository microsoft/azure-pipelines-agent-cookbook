var cfgm = require("./configuration");
var cm = require('./common');
var webapi = require('vso-node-api/WebApi');;


var cfgr = new cfgm.Configurator();

var _creds;
cm.readBasicCreds().then(function (credentials) {
    _creds = credentials;
    action = process.argv.slice(2)[0];
    settings = cfgm.read();
    var agentPoolId;
    if (action == 'install') {
        console.info("Trying to create agent")
        return cfgr.create(credentials).fail(function (err) {
            // we couldn't create agent, then we try to update
            console.info("Trying to update agent")
            cfgr.update(credentials, settings)
        })
    } else if (action == 'remove') {
        console.info("Trying to remove agent")
        var agentApi = new webapi.WebApi(settings.serverUrl, cm.basicHandlerFromCreds(credentials)).getQTaskAgentApi();
        agentApi.connect()
            .then(function (connected) {
              console.log('successful connect as ' + connected.authenticatedUser.customDisplayName);
              return agentApi.getAgentPools(settings.poolName, null);
            }).then(function (agentPools) {
              if (agentPools.length == 0) {
                  throw new Error(settings.poolName + ' pool does not exist.');
              }
              // we queried by name so should only get 1
              agentPoolId = agentPools[0].id;
              console.log('Retrieved agent pool: ' + agentPools[0].name + ' (' + agentPoolId + ')');
              return agentApi.getAgents(agentPoolId, settings.agentName);
            }).then(function (agents) {
              if (agents.length == 1) {
                  console.log('Found agent in pool ' + agents[0].name + ' (' + agentPoolId + ')');
                  var agentId = agents[0].id;
                  agentApi.deleteAgent(agentPoolId, agentId);
              } else {
                  console.log('Not found agents in pool '+ agentPoolId);
              }
            });


    } else {
        console.error("Wrong action. Must be install or remove")
        process.exit(1);
    }

}).fail(function (err) {

    console.error('Error starting the agent');
    console.error(err.message);
    process.exit(1);
});
