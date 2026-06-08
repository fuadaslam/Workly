import re

file_path = '/Users/fuadaslam/fuad/service_manager_app/lib/features/dashboard/presentation/widgets/super_admin_view.dart'
with open(file_path, 'r') as f:
    content = f.read()

# We need 1 more `),` before `],` at line 2240 and 2596.
# Let's fix _AgentManagementTab
agent_target = """                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildLargeAgentCard"""
agent_replace = """                ],
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
content = content.replace(agent_target, agent_replace)

# Let's fix _AccessControlTab
access_target = """              ],
            ),
          ),
        ),
      ),
      ],
    );
  }
}

class _SystemSettingsTab"""
access_replace = """              ],
            ),
          ),
        ),
        ),
      ),
      ],
    );
  }
}

class _SystemSettingsTab"""
content = content.replace(access_target, access_replace)

with open(file_path, 'w') as f:
    f.write(content)

print("Syntax fixed 2")
