import PropTypes from 'prop-types';
import React, { useState } from 'react';
import { useDispatch } from 'react-redux';
import {
  TextList,
  TextContent,
  TextListVariants,
  Card,
  CardBody,
  CardHeader,
  CardActions,
  CardTitle,
  Level,
  LabelGroup,
  Button,
  Tooltip,
} from '@patternfly/react-core';

import UserIcon from '@patternfly/react-icons/dist/esm/icons/user-icon';
import UsersIcon from '@patternfly/react-icons/dist/esm/icons/users-icon';
import ClusterIcon from '@patternfly/react-icons/dist/esm/icons/cluster-icon';
import SyncAltIcon from '@patternfly/react-icons/dist/esm/icons/sync-alt-icon';

import { translate as __ } from 'foremanReact/common/I18n';
import { addToast } from 'foremanReact/components/ToastsList';

import './Properties.scss';
import StatusPropertiesLabel from './StatusPropertiesLabel';
import TextInputField from './TextInputField';
import {
  RESOURCE_IDENTIFIER_NAME,
  RESOURCE_IDENTIFIER_DESCRIPTION,
  RESOURCE_IDENTIFIER_STATUS_NUM_HOSTS,
  RESOURCE_IDENTIFIER_STATUS_NUM_USERS,
  RESOURCE_IDENTIFIER_STATUS_NUM_USERGROUPS,
} from '../../ResourceQuotaFormConstants';

const Properties = ({
  isNewQuota,
  initialName,
  initialDescription,
  initialStatus,
  handleInputValidation,
  onChange,
  onApply,
  onFetch,
}) => {
  const dispatch = useDispatch();
  const tooltipRefFetchButton = React.useRef();

  const [isFetchLoading, setIsFetchLoading] = useState(false);
  const [statusProperties] = useState(initialStatus);

  const onClickFetch = () => {
    onFetch(callbackFetch);
    setIsFetchLoading(true);
  };

  const callbackFetch = (success, response) => {
    setIsFetchLoading(false);
    if (success) {
      dispatch(
        addToast({
          type: 'success',
          message: __(`Sucessfully fetched latest data.`),
        })
      );
    } else {
      dispatch(
        addToast({
          type: 'warning',
          message: __(
            `An error occurred fetching quota information: ${response.response.data.error.full_messages}`
          ),
        })
      );
    }
  };

  return (
    <Card>
      <CardHeader>
        {!isNewQuota && (
          <CardActions>
            <Button
              isLoading={isFetchLoading}
              icon={<SyncAltIcon />}
              isSmall
              onClick={onClickFetch}
              ref={tooltipRefFetchButton}
            />
            <Tooltip
              content={
                <div>
                  <b> {__('Fetch quota utilization')} </b>
                  <div>
                    {__(
                      'This can take some time since the resources of every host, assigned to this quota, must be requested.'
                    )}
                  </div>
                </div>
              }
              reference={tooltipRefFetchButton}
            />
          </CardActions>
        )}
        {isNewQuota ? (
          <CardTitle>{__('Properties')}</CardTitle>
        ) : (
          <Level hasGutter>
            <CardTitle>{__('Properties')}</CardTitle>
            <LabelGroup isCompact>
              <StatusPropertiesLabel
                color="blue"
                iconChild={<ClusterIcon />}
                statusContent={
                  statusProperties[RESOURCE_IDENTIFIER_STATUS_NUM_HOSTS]
                }
                linkUrl={`/hosts?search=resource_quota="${initialName}"`}
                tooltipText="Number of assigned hosts"
              />
              <StatusPropertiesLabel
                color="blue"
                iconChild={<UserIcon />}
                statusContent={
                  statusProperties[RESOURCE_IDENTIFIER_STATUS_NUM_USERS]
                }
                linkUrl={`/users?search=resource_quota="${initialName}"`}
                tooltipText="Number of assigned users"
              />
              <StatusPropertiesLabel
                color="blue"
                iconChild={<UsersIcon />}
                statusContent={
                  statusProperties[RESOURCE_IDENTIFIER_STATUS_NUM_USERGROUPS]
                }
                linkUrl={`/usergroups?search=resource_quota="${initialName}"`}
                tooltipText="Number of assigned usergroups"
              />
            </LabelGroup>
          </Level>
        )}
      </CardHeader>
      <CardBody>
        <TextContent>
          <TextList component={TextListVariants.dl}>
            <TextInputField
              initialValue={initialName}
              isNewQuota={isNewQuota}
              label={__('Name')}
              attribute={RESOURCE_IDENTIFIER_NAME}
              handleInputValidation={handleInputValidation}
              onApply={onApply}
              onChange={onChange}
              isRestrictInputValidation
              isRequired
            />
            <TextInputField
              initialValue={initialDescription}
              isNewQuota={isNewQuota}
              label={__('Description')}
              attribute={RESOURCE_IDENTIFIER_DESCRIPTION}
              handleInputValidation={handleInputValidation}
              onApply={onApply}
              onChange={onChange}
              isTextArea
            />
          </TextList>
        </TextContent>
      </CardBody>
    </Card>
  );
};

Properties.defaultProps = {
  initialName: '',
  initialDescription: '',
  initialStatus: {
    [RESOURCE_IDENTIFIER_STATUS_NUM_HOSTS]: null,
    [RESOURCE_IDENTIFIER_STATUS_NUM_USERS]: null,
    [RESOURCE_IDENTIFIER_STATUS_NUM_USERGROUPS]: null,
  },
};

Properties.propTypes = {
  isNewQuota: PropTypes.bool.isRequired,
  initialName: PropTypes.string,
  initialDescription: PropTypes.string,
  initialStatus: PropTypes.shape({
    [RESOURCE_IDENTIFIER_STATUS_NUM_HOSTS]: PropTypes.number,
    [RESOURCE_IDENTIFIER_STATUS_NUM_USERS]: PropTypes.number,
    [RESOURCE_IDENTIFIER_STATUS_NUM_USERGROUPS]: PropTypes.number,
  }),
  handleInputValidation: PropTypes.func.isRequired,
  onChange: PropTypes.func.isRequired,
  onApply: PropTypes.func.isRequired,
  onFetch: PropTypes.func.isRequired,
};

export default Properties;
