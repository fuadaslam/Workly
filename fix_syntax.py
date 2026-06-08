import re

file_path = '/Users/fuadaslam/fuad/service_manager_app/lib/features/dashboard/presentation/widgets/super_admin_view.dart'
with open(file_path, 'r') as f:
    content = f.read()

# 1. _BranchManagementTab
branch_end_target = """              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceDashboard"""
branch_end_replace = """              ),
            ),
          ),
        ),
      ),
      ],
    );
  }

  Widget _buildPerformanceDashboard"""
content = content.replace(branch_end_target, branch_end_replace)

# 2. _AdminManagementTab
admin_end_target = """              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip"""
admin_end_replace = """              ),
            ),
          ),
        ),
      ),
      ],
    );
  }

  Widget _buildFilterChip"""
content = content.replace(admin_end_target, admin_end_replace)

# 3. _AgentManagementTab
agent_end_target = """              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeAgentCard"""
agent_end_replace = """              ),
            ),
          ),
        ),
      ),
      ],
    );
  }

  Widget _buildLargeAgentCard"""
content = content.replace(agent_end_target, agent_end_replace)

# 4. _AccessControlTab
access_end_target = """              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SystemSettingsTab"""
access_end_replace = """              ],
            ),
          ),
        ),
      ),
      ],
    );
  }
}

class _SystemSettingsTab"""
content = content.replace(access_end_target, access_end_replace)

# 5. _SystemSettingsTab
system_end_target = """              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem"""
system_end_replace = """              ],
            ),
          ),
        ),
      ),
      ],
    );
  }

  Widget _buildLogItem"""
content = content.replace(system_end_target, system_end_replace)

with open(file_path, 'w') as f:
    f.write(content)

print("Syntax fixed")
