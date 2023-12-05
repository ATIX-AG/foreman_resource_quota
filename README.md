# Foreman Resource Quota

Foreman plugin to allow resource management with resource quotas among users and usergroups.

## Installation

_TODO_ Still under development: Will be updated as soon as the Ruby gem,  foreman-installer, or rpm is available.

## Compatibility

| Foreman Version | Plugin Version |
| --------------- | -------------- |
| 3.5             |    0.0.1       |

## Usage

_TODO_ Still under development: Official documentation will be added soon.

When several users share a compute resource or infrastructure, there is a concern that some users could use more than its fair share of resources. Resource quotas are a tool for administrators to address this concern. They limit access to the shared resource in order to guarantee a fair collaboration.

In the context of Foreman, multiple users or groups usually share a fixed number of resources (limitation of compute resources like RAM, disk space, and CPU cores). As of now, a user cannot be limited when allocating resources. They can create hosts with as many resources as they want. This could lead to over-usage or unequal balancing of resources under the users.

This plugin introduces the configuration of resource quotas. A quota limits specific resources and can be applied to a user or a user group. If a user belongs to a user group, the group’s quota is automatically applied to the user as well. When deploying a new host, a user has to choose a resource quota that the host counts to.

A user is hindered from deploying new hosts, if the new host would exceed the corresponding quota limits. In case, a user belongs to multiple user group with quota, the user can determine which quota new hosts belong to. 


## Contributing

Fork and send a Pull Request. Thanks!

## Copyright

Copyright (c) 2023 ATIX AG - https://atix.de

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

