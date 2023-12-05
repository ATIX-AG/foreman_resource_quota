import React, { useState } from 'react';
import { Button, Modal, ModalVariant } from '@patternfly/react-core';

import { translate as __ } from 'foremanReact/common/I18n';
import EmptyStatePattern from 'foremanReact/components/common/EmptyState/EmptyStatePattern';

import ResourceQuotaForm from '../ResourceQuotaForm';
import { MODAL_ID_CREATE_RESOURCE_QUOTA } from '../ResourceQuotaForm/ResourceQuotaFormConstants';

const ResourceQuotaEmptyState = () => {
  const [isOpen, setIsOpen] = useState(false);

  const onSubmitSuccessCallback = success => {
    if (success) {
      setIsOpen(false);
      window.location.reload();
    }
  };

  const ActionButton = (
    <Button
      id="foreman-resource-quota-welcome-create-modal-button"
      variant="primary"
      onClick={() => {
        setIsOpen(true);
      }}
    >
      {__('Create resource quota')}
    </Button>
  );
  return (
    <div>
      <EmptyStatePattern
        icon="pficon pficon-cluster"
        iconType="pf"
        header={__('Resource Quotas')}
        description={__(
          'Resource Quotas help admins to manage hardware resources (like CPUs, RAM, and disk space) among users or usergroups. \n\rDefine a Resource Quota here and apply it to users in order to guarantee a free share of your resources.'
        )}
        action={ActionButton}
      />
      <Modal
        ouiaId={MODAL_ID_CREATE_RESOURCE_QUOTA}
        title={__('Create resource quota')}
        variant={ModalVariant.small}
        isOpen={isOpen}
        onClose={() => {
          setIsOpen(false);
        }}
        appendTo={document.body}
      >
        <ResourceQuotaForm isNewQuota onSubmit={onSubmitSuccessCallback} />
      </Modal>
    </div>
  );
};

export default ResourceQuotaEmptyState;
