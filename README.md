# Foreman Resource Quota

When several users share a compute resource or infrastructure, there is a concern that some users could use more than its fair share of resources. Resource quotas are a tool for administrators to address this concern. They limit access to the shared resource in order to guarantee a fair collaboration.

Talking about Foreman, multiple users or groups usually share a fixed number of resources (limitation of compute resources like RAM, disk storage, and CPU power). As of now, a user cannot be limited when allocating resources. They can create hosts with as many resources as they want. This could lead to over-usage or unequal balancing of resources under the users. In order to prevent this, we want to introduce a new plugin: Foreman Resource Quota.

This plugin introduces the configuration of quotas. A quota limits specific resources and can be applied to a user or a user group. If a user belongs to a user group, the group’s quota is automatically applied to the user as well.

A user is hindered from deploying new hosts, if the new host would exceed the corresponding quota limits. In case, a user belongs to multiple user group with quota, the user can determine which quota new hosts belong to. 

## Installation

See [How_to_Install_a_Plugin](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Plugin)
for how to install Foreman plugins

## Usage

*Usage here*

## TODO

*Todo list here*

## Contributing

Fork and send a Pull Request. Thanks!

## Copyright

Copyright (c) *year* *your name*

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

