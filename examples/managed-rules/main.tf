module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "policy" {
  source  = "codectl/wafwp/azure"
  version = "~> 1.0"

  policy = {
    name                = module.naming.web_application_firewall_policy.name
    resource_group_name = module.rg.groups.demo.name
    location            = "westeurope"
    policy_settings = {
      enabled = true
      mode    = "Prevention"

      log_scrubbing = {
        rules = {
          scrub_auth_header = {
            match_variable = "RequestHeaderNames"
            selector       = "Authorization"
          }
        }
      }
    }
    managed_rules = {
      managed_rule_sets = {
        owasp = {
          type    = "OWASP"
          version = "3.2"
          rule_group_overrides = {
            sql_injection = {
              rule_group_name = "REQUEST-942-APPLICATION-ATTACK-SQLI"
              rules = {
                rule1 = {
                  id      = "942200"
                  enabled = false
                }
                rule2 = {
                  id     = "942210"
                  action = "Log"
                }
              }
            }
          }
        }

        bot_protection = {
          type    = "Microsoft_BotManagerRuleSet"
          version = "1.1"
          rule_group_overrides = {
            bad_bots = {
              rule_group_name = "BadBots"
            }
          }
        }
      }

      exclusions = {
        api_endpoint = {
          match_variable          = "RequestArgValues"
          selector                = "/api/v1/special-endpoint"
          selector_match_operator = "Contains"
          excluded_rule_set = {
            type = "OWASP"
            rule_groups = {
              sqli = {
                rule_group_name = "REQUEST-942-APPLICATION-ATTACK-SQLI"
                excluded_rules  = ["942200", "942210", "942260"]
              }
            }
          }
        }
      }
    }
  }
}
