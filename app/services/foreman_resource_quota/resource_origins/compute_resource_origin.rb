# frozen_string_literal: true

module ForemanResourceQuota
  module ResourceOrigin
    class ComputeResourceOrigin < ResourceOrigin
      def extract_cpu_cores(param)
        param.cpus
      rescue StandardError
        nil
      end

      def extract_memory_mb(param)
        param.memory.to_i / FACTOR_B_TO_MB
      rescue StandardError
        nil
      end

      def extract_disk_gb(_)
        # FIXME: no disk given in VM (compare fog extensions)
        nil
      end

      def collect_resources!(resources_sum, missing_res_per_host)
        compute_resource_to_hosts = group_hosts_by_compute_resource(missing_res_per_host.keys)

        compute_resource_to_hosts.each do |compute_resource_id, hosts|
          next if compute_resource_id == :nil_compute_resource

          host_vms, vm_id_attr = filter_vms_by_hosts(hosts, compute_resource_id)
          next if host_vms.empty?

          hosts.each do |host|
            process_host_vm!(resources_sum, missing_res_per_host, host, host_vms, vm_id_attr)
          end
        end
      end

      def process_host_vm!(resources_sum, missing_res_per_host, host, host_vms, vm_id_attr)
        vm = host_vms.find { |obj| obj.send(vm_id_attr) == host.uuid }
        return unless vm

        missing_res_per_host[host.id].reverse_each do |resource_name| # reverse: delete items while iterating
          process_resource!(resources_sum, missing_res_per_host, resource_name, host.id, vm)
        end
        missing_res_per_host.delete(host.id) if missing_res_per_host[host.id].empty?
      end

      def group_hosts_by_compute_resource(host_ids)
        Host::Managed.where(id: host_ids).includes(:compute_resource).group_by do |host|
          host.compute_resource&.id || :nil_compute_resource
        end
      end

      def filter_vms_by_hosts(hosts, compute_resource_id)
        host_uuids = hosts.map(&:uuid)
        vms = ComputeResource.find_by(id: compute_resource_id).vms.all
        id_attr = vms[0].respond_to?(:vmid) ? :vmid : :id
        filtered_vms = vms.select { |obj| host_uuids.include?(obj.send(id_attr)) } # reduce from all vms
        [filtered_vms, id_attr]
      end
    end
  end
end
