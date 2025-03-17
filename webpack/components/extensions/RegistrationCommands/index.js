import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { noop } from 'foremanReact/common/helpers';

import ResourceQuota from './fields/ResourceQuota';

export const RegistrationResourceQuota = ({
  pluginValues,
  pluginData,
  onChange,
  handleInvalidField,
  isLoading,
}) => {
  useEffect(() => {
    onChange({ availableQuotas: [] });
  }, [onChange]);

  useEffect(() => {
    onChange({ availableQuotas: pluginData?.availableQuotas });
  }, [onChange, pluginData?.availableQuotas]);

  return (
    <ResourceQuota
      availableQuotas={pluginData?.availableQuotas}
      selectedKeys={pluginValues?.selectedQuota || {}}
      pluginValues={pluginValues}
      onChange={onChange}
      handleInvalidField={handleInvalidField}
      isLoading={isLoading}
    />
  );
};

RegistrationResourceQuota.propTypes = {
  pluginValues: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  pluginData: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  onChange: PropTypes.func,
  handleInvalidField: PropTypes.func,
  isLoading: PropTypes.bool,
};

RegistrationResourceQuota.defaultProps = {
  pluginValues: {},
  pluginData: {},
  isLoading: false,
  onChange: noop,
  handleInvalidField: noop,
};
