import React from 'react';
import PropTypes from 'prop-types';
import { Grid, GridItem } from '@patternfly/react-core';

import Resource from './Resource/';
import {
  RESOURCE_IDENTIFIER_CPU,
  RESOURCE_IDENTIFIER_MEMORY,
  RESOURCE_IDENTIFIER_DISK,
} from '../ResourceQuotaFormConstants';

const Resources = ({
  initialStatus,
  initialProperties,
  isNewQuota,
  handleInputValidation,
  onChange,
  onApply,
}) => (
  <Grid span={12} hasGutter>
    <GridItem span={12} key="resources-resource-quota-cpu-item">
      <Resource
        isNewQuota={isNewQuota}
        resourceIdentifier={RESOURCE_IDENTIFIER_CPU}
        initialValue={initialProperties[RESOURCE_IDENTIFIER_CPU]}
        resourceUtilization={initialStatus[RESOURCE_IDENTIFIER_CPU]}
        handleInputValidation={handleInputValidation}
        onChange={onChange}
        onApply={onApply}
      />
    </GridItem>
    <GridItem span={12} key="resources-resource-quota-memory-item">
      <Resource
        isNewQuota={isNewQuota}
        resourceIdentifier={RESOURCE_IDENTIFIER_MEMORY}
        initialValue={initialProperties[RESOURCE_IDENTIFIER_MEMORY]}
        resourceUtilization={initialStatus[RESOURCE_IDENTIFIER_MEMORY]}
        handleInputValidation={handleInputValidation}
        onChange={onChange}
        onApply={onApply}
      />
    </GridItem>
    <GridItem span={12} key="resources-resource-quota-disk-item">
      <Resource
        isNewQuota={isNewQuota}
        resourceIdentifier={RESOURCE_IDENTIFIER_DISK}
        initialValue={initialProperties[RESOURCE_IDENTIFIER_DISK]}
        resourceUtilization={initialStatus[RESOURCE_IDENTIFIER_DISK]}
        handleInputValidation={handleInputValidation}
        onChange={onChange}
        onApply={onApply}
      />
    </GridItem>
  </Grid>
);

Resources.defaultProps = {
  initialStatus: {
    [RESOURCE_IDENTIFIER_CPU]: null,
    [RESOURCE_IDENTIFIER_MEMORY]: null,
    [RESOURCE_IDENTIFIER_DISK]: null,
  },
  initialProperties: {
    [RESOURCE_IDENTIFIER_CPU]: null,
    [RESOURCE_IDENTIFIER_MEMORY]: null,
    [RESOURCE_IDENTIFIER_DISK]: null,
  },
};

Resources.propTypes = {
  initialStatus: PropTypes.shape({
    [RESOURCE_IDENTIFIER_CPU]: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.oneOf([null]),
    ]),
    [RESOURCE_IDENTIFIER_MEMORY]: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.oneOf([null]),
    ]),
    [RESOURCE_IDENTIFIER_DISK]: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.oneOf([null]),
    ]),
  }),
  initialProperties: PropTypes.shape({
    [RESOURCE_IDENTIFIER_CPU]: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.oneOf([null]),
    ]),
    [RESOURCE_IDENTIFIER_MEMORY]: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.oneOf([null]),
    ]),
    [RESOURCE_IDENTIFIER_DISK]: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.oneOf([null]),
    ]),
  }),
  isNewQuota: PropTypes.bool.isRequired,
  handleInputValidation: PropTypes.func.isRequired,
  onChange: PropTypes.func.isRequired,
  onApply: PropTypes.func.isRequired,
};

export default Resources;
