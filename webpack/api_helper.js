import { addToast } from 'foremanReact/components/ToastsList';
import { translate as __ } from 'foremanReact/common/I18n';
import { get, put, post } from 'foremanReact/redux/API';

/* API constants */
const RESOURCE_QUOTA_KEY = 'RESOURCE_QUOTAS';

export const resourceQuotaKey = quotaId => {
  if (quotaId) return `${RESOURCE_QUOTA_KEY}_${quotaId}`;
  return `${RESOURCE_QUOTA_KEY}`;
};

/* perform an API call to list all existing Resource Quotas */
const apiListResourceQuotas = (stateCallback, componentCallback) =>
  get({
    key: resourceQuotaKey(),
    url: `/foreman_resource_quota/api/v2/resource_quotas`,
    handleSuccess: response => stateCallback(true, response, componentCallback),
    handleError: response => stateCallback(false, response, componentCallback),
  });

/* perform an API call to get basic information on a Resource Quota */
const apiGetResourceQuota = (quotaId, stateCallback, componentCallback) =>
  get({
    key: resourceQuotaKey(),
    url: `/foreman_resource_quota/api/v2/resource_quotas/${quotaId}`,
    handleSuccess: response => stateCallback(true, response, componentCallback),
    handleError: response => stateCallback(false, response, componentCallback),
  });

/* perform an API call to determine information on a Resource Quota's utilization */
const apiGetResourceQuotaUtilization = (
  quotaId,
  stateCallback,
  componentCallback
) =>
  get({
    key: resourceQuotaKey(),
    url: `/foreman_resource_quota/api/v2/resource_quotas/${quotaId}/utilization`,
    handleSuccess: response => stateCallback(true, response, componentCallback),
    handleError: response => stateCallback(false, response, componentCallback),
  });

/* perform an API call to create a new Resource Quota */
const apiCreateResourceQuota = (payload, stateCallback, componentCallback) =>
  post({
    key: resourceQuotaKey(),
    url: `/foreman_resource_quota/api/v2/resource_quotas`,
    params: { resource_quota: payload },
    handleSuccess: response => stateCallback(true, response, componentCallback),
    handleError: response => stateCallback(false, response, componentCallback),
  });

/* perform an API call to update Resource Quota data */
const apiUpdateResourceQuota = (
  quotaId,
  payload,
  stateCallback,
  componentCallback
) =>
  put({
    key: resourceQuotaKey(quotaId),
    url: `/foreman_resource_quota/api/v2/resource_quotas/${quotaId}`,
    params: { resource_quota: payload },
    handleSuccess: response => stateCallback(true, response, componentCallback),
    handleError: response => stateCallback(false, response, componentCallback),
  });

/**
 * Handles the callback response from an asynchronous operation, displaying a toast message accordingly.
 * @param {boolean} isSuccess - Indicates whether the operation was successful or not.
 * @param {object} response - The response object returned from the operation.
 * @param {string} successMessage - The success message to display in case of success.
 * @param {string} errorMessage - The error message to display in case of failure.
 */
const dispatchAPICallbackToast = (
  isSuccess,
  response,
  successMessage,
  errorMessage
) => dispatch => {
  if (isSuccess) {
    dispatch(
      addToast({
        type: 'success',
        message: __(successMessage),
      })
    );
  } else {
    let printErrorMessage = __(errorMessage);
    /* eslint-disable-next-line camelcase */
    if (response?.response?.data?.error?.full_messages) {
      printErrorMessage += __(` ${response.response.data.error.full_messages}`);
    }
    dispatch(
      addToast({
        type: 'warning',
        message: printErrorMessage,
      })
    );
  }
};

export {
  apiListResourceQuotas,
  apiGetResourceQuota,
  apiGetResourceQuotaUtilization,
  apiCreateResourceQuota,
  apiUpdateResourceQuota,
  dispatchAPICallbackToast,
};
