![Ruby Lint & Tests](https://github.com/ATIX-AG/foreman_resource_quota/actions/workflows/ruby_tests.yml/badge.svg)
![Javascript Lint & Tests](https://github.com/ATIX-AG/foreman_resource_quota/actions/workflows/js_tests.yml/badge.svg)

# Foreman Resource Quota

Foreman plugin to allow resource management with Resource Quotas among users and usergroups.
For more information, see [Limiting host resources](https://docs.theforeman.org/nightly/Administering_Project/index-katello.html#limiting-host-resources).

## Installation

[Installing the Resource Quota plugin](https://docs.theforeman.org/nightly/Administering_Project/index-katello.html#installing-the-resource-quota-plugin)

## Compatibility

| Foreman Version | Plugin Version |
| --------------- | -------------- |
| 3.15            |    0.5.0       |
| 3.14            |    0.4.0       |
| 3.13            | ~> 0.3.0       |
| 3.5             |    0.0.1       |

## Usage

When several users share a compute resource or infrastructure, there is a concern that some users could use more than its fair share of resources. Resource Quotas are a tool for administrators to address this concern. They limit access to the shared resource in order to guarantee a fair collaboration.

In the context of Foreman, multiple users or groups usually share a fixed number of resources (limitation of compute resources like CPU cores, memory, and disk space). As of now, a user cannot be limited when allocating resources. They can create hosts with as many resources as they want. This could lead to over-usage or unequal balancing of resources under the users.

This plugin introduces the configuration of Resource Quotas. A quota limits specific resources and can be applied to a user or a user group. If a user belongs to a user group, the group’s quota is automatically applied to the user as well. When deploying a new host, a user has to choose a Resource Quota that the host counts to.

A user is hindered from deploying new hosts, if the new host would exceed the corresponding quota limits. In case, a user belongs to multiple user group with quota, the user can determine which quota new hosts belong to.


## Contributing

Fork and send a Pull Request. Thanks!

## Version Update

1. Create a feature branch `bump/version_x.y.z` and add a version bump commit
2. If all checks are fine, merge the commit and pull the latest `main` locally
3. Add a version tag afterwards on `main` and push it

## Copyright

Copyright (c) 2025 ATIX AG - https://atix.de

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
