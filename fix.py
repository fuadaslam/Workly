import re

file_path = '/Users/fuadaslam/fuad/service_manager_app/lib/features/dashboard/presentation/widgets/super_admin_view.dart'
with open(file_path, 'r') as f:
    content = f.read()

def modify_tab(content, top_search, top_replace, bot_search, bot_replace):
    if top_search in content and bot_search in content:
        content = content.replace(top_search, top_replace)
        content = content.replace(bot_search, bot_replace)
    else:
        print(f"Failed to find match.")
        if top_search not in content: print("Missing top:", repr(top_search))
        if bot_search not in content: print("Missing bot:", repr(bot_search))
    return content

# 1. _BranchManagementTab
branch_top = """    return ResponsiveLayout(
      maxWidth: 1000,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _HeaderSection(title: l10n.regionalOffices, subtitle: l10n.branchManagement.toUpperCase(), showDate: false),
          Expanded(
            child: RefreshIndicator("""
branch_top_rep = """    return Column(
      children: [
        _HeaderSection(title: l10n.regionalOffices, subtitle: l10n.branchManagement.toUpperCase(), showDate: false),
        Expanded(
          child: ResponsiveLayout(
            maxWidth: 1000,
            padding: EdgeInsets.zero,
            child: RefreshIndicator("""

branch_bot = """                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildPerformanceDashboard"""
branch_bot_rep = """                ],
              ),
            ),
          ),
        ),
        ),
        ],
      ),
    );
  }

  Widget _buildPerformanceDashboard"""
content = modify_tab(content, branch_top, branch_top_rep, branch_bot, branch_bot_rep)


# 2. _LeaveManagementTab
leave_top = """    return ResponsiveLayout(
      maxWidth: 1000,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _HeaderSection(
            title: l10n.leaveManagement, 
            subtitle: l10n.leaves.toUpperCase(),
            showDate: false,
          ),
          const Expanded(
            child: AdminLeaveList(),
          ),
        ],
      ),
    );
  }"""
leave_top_rep = """    return Column(
      children: [
        _HeaderSection(
          title: l10n.leaveManagement, 
          subtitle: l10n.leaves.toUpperCase(),
          showDate: false,
        ),
        const Expanded(
          child: ResponsiveLayout(
            maxWidth: 1000,
            padding: EdgeInsets.zero,
            child: AdminLeaveList(),
          ),
        ),
      ],
    );
  }"""
if leave_top in content:
    content = content.replace(leave_top, leave_top_rep)
else:
    print("Leave top not found")

# 3. _AdminManagementTab
admin_top = """    return ResponsiveLayout(
      maxWidth: 1000,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _HeaderSection(
            title: isStaffView ? l10n.staffCommandCenter : l10n.totalControlHub, 
            subtitle: (isStaffView ? l10n.manageStaff : l10n.manageAdmins).toUpperCase()
          ),
          Expanded(
            child: RefreshIndicator("""
admin_top_rep = """    return Column(
      children: [
        _HeaderSection(
          title: isStaffView ? l10n.staffCommandCenter : l10n.totalControlHub, 
          subtitle: (isStaffView ? l10n.manageStaff : l10n.manageAdmins).toUpperCase()
        ),
        Expanded(
          child: ResponsiveLayout(
            maxWidth: 1000,
            padding: EdgeInsets.zero,
            child: RefreshIndicator("""

admin_bot = """                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildFilterChip"""
admin_bot_rep = """                ],
              ),
            ),
          ),
        ),
        ),
        ],
      ),
    );
  }

  Widget _buildFilterChip"""
content = modify_tab(content, admin_top, admin_top_rep, admin_bot, admin_bot_rep)

# 4. _AgentManagementTab
agent_top = """    return ResponsiveLayout(
      maxWidth: 1000,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _HeaderSection(
            title: l10n.agents, 
            subtitle: l10n.allAgents.toUpperCase()
          ),
          Expanded(
            child: RefreshIndicator("""
agent_top_rep = """    return Column(
      children: [
        _HeaderSection(
          title: l10n.agents, 
          subtitle: l10n.allAgents.toUpperCase()
        ),
        Expanded(
          child: ResponsiveLayout(
            maxWidth: 1000,
            padding: EdgeInsets.zero,
            child: RefreshIndicator("""

agent_bot = """                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildLargeAgentCard"""
agent_bot_rep = """                ],
              ),
            ),
          ),
        ),
        ),
        ],
      ),
    );
  }

  Widget _buildLargeAgentCard"""
content = modify_tab(content, agent_top, agent_top_rep, agent_bot, agent_bot_rep)

# 5. _AccessControlTab
access_top = """    return ResponsiveLayout(
      maxWidth: 1000,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _HeaderSection(
            title: l10n.accessControl, 
            subtitle: l10n.security.toUpperCase(),
            showDate: false,
          ),
          Expanded(
            child: ListView("""
access_top_rep = """    return Column(
      children: [
        _HeaderSection(
          title: l10n.accessControl, 
          subtitle: l10n.security.toUpperCase(),
          showDate: false,
        ),
        Expanded(
          child: ResponsiveLayout(
            maxWidth: 1000,
            padding: EdgeInsets.zero,
            child: ListView("""

access_bot = """              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemSettingsTab"""
access_bot_rep = """              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}

class _SystemSettingsTab"""
content = modify_tab(content, access_top, access_top_rep, access_bot, access_bot_rep)

# 6. _SystemSettingsTab
system_top = """    return ResponsiveLayout(
      maxWidth: 1000,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _HeaderSection(title: l10n.systemAuthority, subtitle: l10n.systemLogs.toUpperCase(), showDate: false),
          Expanded(
            child: ListView("""
system_top_rep = """    return Column(
      children: [
        _HeaderSection(title: l10n.systemAuthority, subtitle: l10n.systemLogs.toUpperCase(), showDate: false),
        Expanded(
          child: ResponsiveLayout(
            maxWidth: 1000,
            padding: EdgeInsets.zero,
            child: ListView("""

system_bot = """              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem"""
system_bot_rep = """              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildLogItem"""
content = modify_tab(content, system_top, system_top_rep, system_bot, system_bot_rep)

with open(file_path, 'w') as f:
    f.write(content)

print("Done")
