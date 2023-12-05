import { useState, useEffect } from 'react';
import { useDispatch } from 'react-redux';

import { deepEqual, deepCopy } from '../../../helper';
import {
  apiCreateResourceQuota,
  apiUpdateResourceQuota,
  apiGetResourceQuota,
  apiGetResourceQuotaUtilization,
} from '../../../api_helper';

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
  RESOURCE_IDENTIFIER_STATUS_UTILIZATION,
  RESOURCE_IDENTIFIER_STATUS_MISSING_HOSTS,
} from '../ResourceQuotaFormConstants';

const QuotaState = ({ initialProperties, initialStatus, changesCallback }) => {
  const defaultProperties = {
    [RESOURCE_IDENTIFIER_ID]: null,
    [RESOURCE_IDENTIFIER_NAME]: '',
    [RESOURCE_IDENTIFIER_DESCRIPTION]: '',
    [RESOURCE_IDENTIFIER_CPU]: null,
    [RESOURCE_IDENTIFIER_MEMORY]: null,
    [RESOURCE_IDENTIFIER_DISK]: null,
  };
  const defaultStatus = {
    [RESOURCE_IDENTIFIER_STATUS_NUM_HOSTS]: null,
    [RESOURCE_IDENTIFIER_STATUS_NUM_USERS]: null,
    [RESOURCE_IDENTIFIER_STATUS_NUM_USERGROUPS]: null,
    [RESOURCE_IDENTIFIER_STATUS_MISSING_HOSTS]: null,
    [RESOURCE_IDENTIFIER_STATUS_UTILIZATION]: {
      [RESOURCE_IDENTIFIER_CPU]: null,
      [RESOURCE_IDENTIFIER_MEMORY]: null,
      [RESOURCE_IDENTIFIER_DISK]: null,
    },
  };
  const dispatch = useDispatch();
  const [quotaProperties, setQuotaProperties] = useState({
    ...defaultProperties,
    ...initialProperties,
  });
  const [quotaStatus, setQuotaStatus] = useState({
    ...defaultStatus,
    ...initialStatus,
  });
  const [isValid, setIsValid] = useState({
    [RESOURCE_IDENTIFIER_NAME]: true,
    [RESOURCE_IDENTIFIER_DESCRIPTION]: true,
    [RESOURCE_IDENTIFIER_CPU]: true,
    [RESOURCE_IDENTIFIER_MEMORY]: true,
    [RESOURCE_IDENTIFIER_DISK]: true,
  });

  /* callback to notify outside listeners that the quota changed */
  useEffect(() => {
    // changesCallback is optional + check if name is defined (otherwise, it's most likely an empty re-render call)
    if (changesCallback && quotaProperties[RESOURCE_IDENTIFIER_NAME])
      changesCallback(quotaProperties, quotaStatus);
  }, [quotaProperties, quotaStatus, changesCallback]);

  /* callback to handle api response and update quota state */
  const apiCallback = (success, response, callback) => {
    if (response.hasOwnProperty('data')) {
      const responseData = response.data;
      const apiProperties = JSON.parse(JSON.stringify(quotaProperties));
      const apiStatus = JSON.parse(JSON.stringify(quotaStatus));

      deepCopy(apiProperties, responseData);
      deepCopy(apiStatus, responseData);

      if (!deepEqual(quotaProperties, apiProperties))
        setQuotaProperties(apiProperties);
      if (!deepEqual(quotaStatus, apiStatus)) setQuotaStatus(apiStatus);
    }
    callback(success, response);
  };

  /* update quotaProperties */
  const onChange = changes => {
    const updatedQuota = { ...quotaProperties, ...changes };
    if (!deepEqual(quotaProperties, updatedQuota)) {
      setQuotaProperties(updatedQuota);
    }
  };

  /* perform API call: apply indidividual changes to existing quota */
  const onApply = (callback, payload) => {
    const quotaId = quotaProperties[RESOURCE_IDENTIFIER_ID];
    dispatch(apiUpdateResourceQuota(quotaId, payload, apiCallback, callback));
  };

  /* perform API call: create a new Resource Quota */
  const onCreate = callback => {
    const payload = (({ [RESOURCE_IDENTIFIER_ID]: _, ...obj }) => obj)(
      quotaProperties
    );
    dispatch(apiCreateResourceQuota(payload, apiCallback, callback));
  };

  /* perform API call: fetch basic information of a Resource Quota */
  const onFetch = callback => {
    const quotaId = quotaProperties[RESOURCE_IDENTIFIER_ID];
    dispatch(apiGetResourceQuota(quotaId, apiCallback, callback));
  };

  /* perform API call: fetch basic information of a Resource Quota */
  const onFetchUtilization = callback => {
    const quotaId = quotaProperties[RESOURCE_IDENTIFIER_ID];
    dispatch(apiGetResourceQuotaUtilization(quotaId, apiCallback, callback));
  };

  /* handle data validity response */
  const handleInputValidation = changes => {
    const isValidChanges = { ...isValid, ...changes };
    if (!deepEqual(isValid, isValidChanges)) {
      setIsValid(isValidChanges);
    }
  };

  /* get the current quota properties */
  const getQuotaProperties = (sub = null) => {
    if (sub) return quotaProperties[sub];
    return quotaProperties;
  };

  /* get the current quota status */
  const getQuotaStatus = (sub = null) => {
    if (sub) return quotaStatus[sub];
    return quotaStatus;
  };

  /* get validity status of current data */
  const getIsValid = () => isValid;

  return {
    getQuotaProperties,
    getQuotaStatus,
    getIsValid,
    handleInputValidation,
    onChange,
    onApply,
    onCreate,
    onFetch,
    onFetchUtilization,
  };
};

export default QuotaState;
