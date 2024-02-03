# frozen_string_literal: true

module ForemanResourceQuota
  module ResourceOrigins
    class ComputeResourceOrigin < ResourceOrigin
      def extract_cpu_cores(param)
        param.cpus
      rescue StandardError
        nil
      end

      def extract_memory_mb(param)
        param.memory.to_i / ResourceQuotaHelper::FACTOR_B_TO_MB
      rescue StandardError
        nil
      end

      def extract_disk_gb(_)
        # FIXME: no disk given in VM (compare fog extensions)
        nil
      end

      def collect_resources!(resources_sum, missing_hosts_resources, _host_objects)
        compute_resource_to_hosts = group_hosts_by_compute_resource(missing_hosts_resources.keys)

        compute_resource_to_hosts.each do |compute_resource_id, hosts|
          next if compute_resource_id == :nil_compute_resource

          host_vms, vm_id_attr = filter_vms_by_hosts(hosts, compute_resource_id)
          next if host_vms.empty?

          hosts.each do |host|
            vm = host_vms.find { |obj| obj.send(vm_id_attr) == host.uuid }
            next unless vm
            process_host_vm!(resources_sum, missing_hosts_resources, host.name, vm)
          end
        end
      end

      # Groups hosts with the same compute resource.
      # Parameters: An array of host names.
      # Returns: A hash where keys represent compute resource IDs and values are the list of host objects.
      def group_hosts_by_compute_resource(host_names)
        Host::Managed.where(name: host_names).includes(:compute_resource).group_by do |host|
          host.compute_resource&.id || :nil_compute_resource
        end
      end

      # Filters VMs of a compute resource, given a list of hosts.
      # Parameters:
      #   - hosts: An array of host objects.
      #   - compute_resource_id: ID of the compute resource.
      # Returns:
      #   - filtered_vms: An array of filtered virtual machine objects.
      #   - id_attr: Attribute used for identifying virtual machines (either :vmid or :id).
      def filter_vms_by_hosts(hosts, compute_resource_id)
        host_uuids = hosts.map(&:uuid)
        vms = ComputeResource.find_by(id: compute_resource_id).vms.all
        id_attr = vms[0].respond_to?(:vmid) ? :vmid : :id
        filtered_vms = vms.select { |obj| host_uuids.include?(obj.send(id_attr)) } # reduce from all vms
        [filtered_vms, id_attr]
      end

      # Processes a host's virtual machines and updates resource allocation.
      # Parameters:
      #   - resources_sum: Hash containing total resources sum.
      #   - missing_hosts_resources: Hash containing missing resources per host.
      #   - host_name: Name of the host.
      #   - vm: Compute resource VM object of given host.
      # Returns: None.
      def process_host_vm!(resources_sum, missing_hosts_resources, host_name, host_vm)
        missing_hosts_resources[host_name].reverse_each do |resource_name|
          resource_value = process_resource(resource_name, host_vm)
          next unless resource_value
          resources_sum[resource_name] += resource_value
          missing_hosts_resources[host_name].delete(resource_name)
        end
        missing_hosts_resources.delete(host_name) if missing_hosts_resources[host_name].empty?
      end
    end
  end
end
