import React, { useState, useEffect, useCallback } from 'react';
import PropTypes from 'prop-types';
import { Gallery, GalleryItem } from '@patternfly/react-core';

import SkeletonLoader from 'foremanReact/components/common/SkeletonLoader';
import { STATUS } from 'foremanReact/constants';

import Properties from './components/Properties/';
import Resources from './components/Resources';
import Submit from './components/Submit';
import QuotaState from './components/QuotaState';
import {
  RESOURCE_IDENTIFIER_ID,
  RESOURCE_IDENTIFIER_NAME,
  RESOURCE_IDENTIFIER_DESCRIPTION,
  RESOURCE_IDENTIFIER_CPU,
  RESOURCE_IDENTIFIER_MEMORY,
  RESOURCE_IDENTIFIER_DISK,
  RESOURCE_IDENTIFIER_STATUS_NUM_HOSTS,
  RESOURCE_IDENTIFIER_STATUS_NUM_USERS,
  RESOURCE_IDENTIFIER_STATUS_NUM_USERGROUPS,
  RESOURCE_IDENTIFIER_STATUS_MISSING_HOSTS,
  RESOURCE_IDENTIFIER_STATUS_UTILIZATION,
} from './ResourceQuotaFormConstants';

const ResourceQuotaForm = ({
  isNewQuota,
  initialProperties,
  initialStatus,
  onSubmit,
  quotaChangesCallback,
}) => {
  const modelState = QuotaState({
    initialProperties,
    initialStatus,
    changesCallback: quotaChangesCallback,
  });

  const [isLoading, setIsLoading] = useState(!isNewQuota);
  const [fetchedOnce, setFetchedOnce] = useState(false);

  const fetchCallback = useCallback(() => {
    setIsLoading(false);
  }, []);

  const fetchQuotaOnce = useCallback(() => {
    if (!isNewQuota && !fetchedOnce) {
      modelState.onFetch(fetchCallback);
      setFetchedOnce(true);
    }
  }, [modelState, isNewQuota, fetchedOnce, fetchCallback]);

  useEffect(() => {
    fetchQuotaOnce(); // this will be executed only on the first render (valid is ignored)
  }, [fetchQuotaOnce]);

  return (
    <Gallery maxWidths={{ md: '800px' }}>
      <Gallery hasGutter>
        <GalleryItem key="edit-resource-quota-properties-item">
          <SkeletonLoader
            skeletonProps={{ width: 300 }}
            status={isNewQuota || !isLoading ? STATUS.RESOLVED : STATUS.PENDING}
          >
            {(!isLoading || isNewQuota) && (
              <Properties
                isNewQuota={isNewQuota}
                initialName={modelState.getQuotaProperties(
                  RESOURCE_IDENTIFIER_NAME
                )}
                initialDescription={modelState.getQuotaProperties(
                  RESOURCE_IDENTIFIER_DESCRIPTION
                )}
                initialStatus={modelState.getQuotaStatus()}
                handleInputValidation={modelState.handleInputValidation}
                onChange={modelState.onChange}
                onApply={modelState.onApply}
                onFetch={modelState.onFetchUtilization}
              />
            )}
          </SkeletonLoader>
        </GalleryItem>
        <GalleryItem key="edit-resource-quota-resources-item">
          <SkeletonLoader
            skeletonProps={{ width: 400 }}
            status={isNewQuota || !isLoading ? STATUS.RESOLVED : STATUS.PENDING}
          >
            {(!isLoading || isNewQuota) && (
              <Resources
                isNewQuota={isNewQuota}
                initialProperties={modelState.getQuotaProperties()}
                initialStatus={modelState.getQuotaStatus(
                  RESOURCE_IDENTIFIER_STATUS_UTILIZATION
                )}
                handleInputValidation={modelState.handleInputValidation}
                onChange={modelState.onChange}
                onApply={modelState.onApply}
              />
            )}
          </SkeletonLoader>
        </GalleryItem>
        {isNewQuota && (
          <GalleryItem key="edit-resource-quota-submit-item">
            <Submit
              isValid={modelState.getIsValid()}
              onCreate={modelState.onCreate}
              onSubmit={onSubmit}
            />
          </GalleryItem>
        )}
      </Gallery>
    </Gallery>
  );
};

ResourceQuotaForm.defaultProps = {
  onSubmit: null,
  quotaChangesCallback: null,
  initialProperties: {
    [RESOURCE_IDENTIFIER_NAME]: '',
    [RESOURCE_IDENTIFIER_DESCRIPTION]: '',
    [RESOURCE_IDENTIFIER_CPU]: null,
    [RESOURCE_IDENTIFIER_MEMORY]: null,
    [RESOURCE_IDENTIFIER_DISK]: null,
  },
  initialStatus: {
    [RESOURCE_IDENTIFIER_STATUS_NUM_HOSTS]: null,
    [RESOURCE_IDENTIFIER_STATUS_NUM_USERS]: null,
    [RESOURCE_IDENTIFIER_STATUS_NUM_USERGROUPS]: null,
    [RESOURCE_IDENTIFIER_STATUS_MISSING_HOSTS]: null,
    [RESOURCE_IDENTIFIER_STATUS_UTILIZATION]: {
      [RESOURCE_IDENTIFIER_CPU]: null,
      [RESOURCE_IDENTIFIER_MEMORY]: null,
      [RESOURCE_IDENTIFIER_DISK]: null,
    },
  },
};

ResourceQuotaForm.propTypes = {
  isNewQuota: PropTypes.bool.isRequired,
  onSubmit: PropTypes.func,
  quotaChangesCallback: PropTypes.func,
  initialProperties: PropTypes.shape({
    [RESOURCE_IDENTIFIER_ID]: PropTypes.number,
    [RESOURCE_IDENTIFIER_NAME]: PropTypes.string,
    [RESOURCE_IDENTIFIER_DESCRIPTION]: PropTypes.string,
    [RESOURCE_IDENTIFIER_CPU]: PropTypes.number,
    [RESOURCE_IDENTIFIER_MEMORY]: PropTypes.number,
    [RESOURCE_IDENTIFIER_DISK]: PropTypes.number,
  }),
  initialStatus: PropTypes.shape({
    [RESOURCE_IDENTIFIER_STATUS_NUM_HOSTS]: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.oneOf([null]),
    ]),
    [RESOURCE_IDENTIFIER_STATUS_NUM_USERS]: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.oneOf([null]),
    ]),
    [RESOURCE_IDENTIFIER_STATUS_NUM_USERGROUPS]: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.oneOf([null]),
    ]),
    [RESOURCE_IDENTIFIER_STATUS_MISSING_HOSTS]: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.oneOf([null]),
    ]),
    [RESOURCE_IDENTIFIER_STATUS_UTILIZATION]: PropTypes.shape({
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
  }),
};

export default ResourceQuotaForm;
