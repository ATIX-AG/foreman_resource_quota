/* Resource identifier */
export const RESOURCE_IDENTIFIER_ID = 'id';
export const RESOURCE_IDENTIFIER_NAME = 'name';
export const RESOURCE_IDENTIFIER_DESCRIPTION = 'description';
export const RESOURCE_IDENTIFIER_CPU = 'cpu_cores';
export const RESOURCE_IDENTIFIER_MEMORY = 'memory_mb';
export const RESOURCE_IDENTIFIER_DISK = 'disk_gb';
export const RESOURCE_IDENTIFIER_STATUS_NUM_HOSTS = 'number_of_hosts';
export const RESOURCE_IDENTIFIER_STATUS_NUM_USERS = 'number_of_users';
export const RESOURCE_IDENTIFIER_STATUS_NUM_USERGROUPS = 'number_of_usergroups';
export const RESOURCE_IDENTIFIER_STATUS_UTILIZATION = 'utilization';
export const RESOURCE_IDENTIFIER_STATUS_MISSING_HOSTS = 'missing_hosts';

/* Resource names */
export const RESOURCE_NAME_CPU = 'CPU cores';
export const RESOURCE_NAME_MEMORY = 'Memory';
export const RESOURCE_NAME_DISK = 'Disk space';

/* Resource units (order the units with increasing factor!) */
export const RESOURCE_UNIT_CPU = [{ symbol: 'cores', factor: 1 }];
export const RESOURCE_UNIT_MEMORY = [
  { symbol: 'MB', factor: 1 },
  { symbol: 'GB', factor: 1024 },
  { symbol: 'TB', factor: 1024 * 1024 },
];
export const RESOURCE_UNIT_DISK = [
  { symbol: 'GB', factor: 1 },
  { symbol: 'TB', factor: 1024 },
  { symbol: 'PB', factor: 1024 * 1024 },
];

/* Resource value bounds */
export const RESOURCE_VALUE_MIN_CPU = 0;
export const RESOURCE_VALUE_MAX_CPU = 1999999999;
export const RESOURCE_VALUE_MIN_MEMORY = 0;
export const RESOURCE_VALUE_MAX_MEMORY = 1999999999;
export const RESOURCE_VALUE_MIN_DISK = 0;
export const RESOURCE_VALUE_MAX_DISK = 1999999999;

/* Map attributes to given resource identifier (name, unit, minValue, maxValue) */
export const resourceAttributesByIdentifier = identifier => {
  switch (identifier) {
    case RESOURCE_IDENTIFIER_CPU:
      return {
        name: RESOURCE_NAME_CPU,
        unit: RESOURCE_UNIT_CPU,
        minValue: RESOURCE_VALUE_MIN_CPU,
        maxValue: RESOURCE_VALUE_MAX_CPU,
      };
    case RESOURCE_IDENTIFIER_MEMORY:
      return {
        name: RESOURCE_NAME_MEMORY,
        unit: RESOURCE_UNIT_MEMORY,
        minValue: RESOURCE_VALUE_MIN_MEMORY,
        maxValue: RESOURCE_VALUE_MAX_MEMORY,
      };
    case RESOURCE_IDENTIFIER_DISK:
      return {
        name: RESOURCE_NAME_DISK,
        unit: RESOURCE_UNIT_DISK,
        minValue: RESOURCE_VALUE_MIN_DISK,
        maxValue: RESOURCE_VALUE_MAX_DISK,
      };
    default:
      return null;
  }
};

/* HTML constants */
export const MODAL_ID_CREATE_RESOURCE_QUOTA = `foreman-resource-quota-create-modal`;
export const MODAL_ID_UPDATE_RESOURCE_QUOTA = `foreman-resource-quota-create-modal`;
