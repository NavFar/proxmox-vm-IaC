ha_resource_rules = {

  separate_test_pair = {
    enabled = true
    type    = "resource-anti-affinity"
    strict  = false

    resources = [
      "test-01",
      "test-02",
    ]

    comment = "Prefer test-01 and test-02 to run separately"
  }
}
