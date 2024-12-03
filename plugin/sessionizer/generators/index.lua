local builtin = {}

builtin.DefaultWorkspace = require "sessionizer.generators.default_workspace".DefaultWorkspace
builtin.MostRecentWorkspace = require "sessionizer.generators.most_recent_workspace".MostRecentWorkspace
builtin.AllActiveWorkspaces = require "sessionizer.generators.all_active_sessions".AllActiveWorkspaces
builtin.FdSearch = require "sessionizer.generators.fd".FdSearch
builtin.Zoxide = require "sessionizer.generators.zoxide".Zoxide

return builtin
