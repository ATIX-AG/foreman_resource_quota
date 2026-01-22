import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import {
  FormGroup,
  FormSelect,
  FormSelectOption,
  FormHelperText,
  HelperTextItem,
  HelperText,
} from '@patternfly/react-core';

import { ExclamationCircleIcon } from '@patternfly/react-icons';
import { translate as __ } from 'foremanReact/common/I18n';

const ResourceQuota = ({
  availableQuotas,
  selectedQuota,
  pluginValues,
  onChange,
  isLoading,
  handleInvalidField,
}) => {
  const validateResouceQuotaField = (selected, all) => {
    if (!all) {
      return true;
    }

    if (all.filter(quota => quota === selected)) {
      return true;
    }
    return false;
  };

  const updatePluginValues = quotas => {
    onChange({ availableQuotas: quotas });
    handleInvalidField(
      'Resource Quota',
      validateResouceQuotaField(selectedQuota, availableQuotas)
    );
  };

  const helperText = valid => {
    if (valid) {
      return '';
    }
    return 'Invalid Resource Quota!';
  };

  const helperValidated = valid => {
    if (valid) {
      return 'default';
    }
    return 'error';
  };

  const onSelect = (_e, value) => {
    updatePluginValues([...selectedQuota, value]);
  };

  // Validate field when hostgroup is changed (host group may have some keys)
  useEffect(() => {
    handleInvalidField(
      'Activation Keys',
      validateResouceQuotaField(selectedQuota, availableQuotas)
    );
  }, [handleInvalidField, selectedQuota, availableQuotas]);

  useEffect(() => {
    if (availableQuotas?.length === 1) {
      onChange({ availableQuotas: [availableQuotas[0].name] });
    }
  }, [availableQuotas, onChange]);

  return (
    <FormGroup
      label={__('Resource Quota')}
      fieldId="resource_quota_field"
      isRequired
    >
      <FormHelperText>
        <HelperText>
          <HelperTextItem
            variant={helperValidated()}
            {...(helperValidated() === 'error' && {
              icon: <ExclamationCircleIcon />,
            })}
          >
            {helperText()}
          </HelperTextItem>
        </HelperText>
      </FormHelperText>
      <FormSelect
        id="selection"
        validated={validateResouceQuotaField(selectedQuota, availableQuotas)}
        value={selectedQuota?.name}
        onChange={onSelect}
        aria-label="FormSelect Input"
      >
        {availableQuotas &&
          availableQuotas.map((option, index) => (
            <FormSelectOption
              key={index}
              value={option.id}
              label={option.name}
            />
          ))}
      </FormSelect>
    </FormGroup>
  );
};

ResourceQuota.propTypes = {
  availableQuotas: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number,
      name: PropTypes.string,
    })
  ),
  selectedQuota: PropTypes.shape({
    id: PropTypes.number,
    name: PropTypes.string,
  }),
  pluginValues: PropTypes.shape({
    availableQuotas: PropTypes.arrayOf(
      PropTypes.shape({
        id: PropTypes.number,
        name: PropTypes.string,
      })
    ),
  }),
  onChange: PropTypes.func.isRequired,
  handleInvalidField: PropTypes.func.isRequired,
  isLoading: PropTypes.bool,
};

ResourceQuota.defaultProps = {
  availableQuotas: undefined,
  selectedQuota: undefined,
  pluginValues: {},
  isLoading: false,
};

export default ResourceQuota;
