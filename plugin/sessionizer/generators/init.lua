local generators = {}

generators.DefaultWorkspace = require "sessionizer.generators.default_workspace".DefaultWorkspace
generators.MostRecentWorkspace = require "sessionizer.generators.most_recent_workspace".MostRecentWorkspace
generators.AllActiveWorkspaces = require "sessionizer.generators.all_active_sessions".AllActiveWorkspaces
generators.FdSearch = require "sessionizer.generators.fd".FdSearch

return generators
