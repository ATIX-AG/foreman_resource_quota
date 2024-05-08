import React, { useState, useEffect, useCallback } from 'react';
import PropTypes from 'prop-types';
import {
  Progress,
  ProgressSize,
  ProgressVariant,
  ProgressMeasureLocation,
  Tooltip,
} from '@patternfly/react-core';
import SyncAltIcon from '@patternfly/react-icons/dist/esm/icons/sync-alt-icon';

import { translate as __ } from 'foremanReact/common/I18n';

import './UtilizationProgress.scss';
import { findLargestFittingUnit } from '../../../../helper';

const UtilizationProgress = ({
  cardId,
  resourceValue,
  resourceUnits,
  resourceUtilization,
  isEnabled,
  isNewQuota,
}) => {
  const [resourceUtilizationPercent, setResourceUtilizationPercent] = useState(
    null
  );
  const [
    resourceUtilizationTooltipText,
    setResourceUtilizationTooltipText,
  ] = useState(<div />);
  const tooltipRefUtilization = React.useRef();

  /* resource utilization bar */
  const resourceProgressVariant = () => {
    if (resourceUtilizationPercent < 80) return null;
    else if (resourceUtilizationPercent < 100) return ProgressVariant.warning;
    return ProgressVariant.danger;
  };

  const updateResourceUtilizationView = useCallback(() => {
    let newPercent;
    let newTooltipText;

    if (isNewQuota) {
      newPercent = 0;
      newTooltipText = (
        <div>
          <div>{__('New quota - no consumption to display.')}</div>
        </div>
      );
    } else if (resourceUtilization == null) {
      newPercent = 0;
      newTooltipText = (
        <div>
          <div>{__('No consumption to display.')}</div>
          <div>
            {__('Click on "Fetch quota utilization": ')}
            <SyncAltIcon />
          </div>
        </div>
      );
    } else if (resourceUtilization > resourceValue) {
      const valueUnit = findLargestFittingUnit(resourceValue, resourceUnits);
      const utilizationUnit = findLargestFittingUnit(
        resourceUtilization,
        resourceUnits
      );
      const utilizationInUnit = resourceUtilization / utilizationUnit.factor;
      const valueInUnit = resourceValue / valueUnit.factor;
      newPercent = 100;
      newTooltipText = (
        <div>
          {`${utilizationInUnit} ${utilizationUnit.symbol} / ${valueInUnit} ${valueUnit.symbol}`}
        </div>
      );
    } else {
      const valueUnit = findLargestFittingUnit(resourceValue, resourceUnits);
      const utilizationUnit = findLargestFittingUnit(
        resourceUtilization,
        resourceUnits
      );
      const utilizationInUnit = resourceUtilization / utilizationUnit.factor;
      const valueInUnit = resourceValue / valueUnit.factor;
      const percent = (100 * resourceUtilization) / resourceValue;
      if (Number.isFinite(percent)) newPercent = percent;
      else newPercent = 0;
      newTooltipText = (
        <div>
          {`${utilizationInUnit} ${utilizationUnit.symbol} / ${valueInUnit} ${valueUnit.symbol}`}
        </div>
      );
    }
    setResourceUtilizationPercent(newPercent);
    setResourceUtilizationTooltipText(newTooltipText);
  }, [isNewQuota, resourceUnits, resourceUtilization, resourceValue]);

  // call it once
  useEffect(() => {
    updateResourceUtilizationView();
  }, [updateResourceUtilizationView]);

  return (
    <div>
      <Tooltip
        content={resourceUtilizationTooltipText}
        reference={tooltipRefUtilization}
      />
      <div
        className={isEnabled ? '' : 'progress-disabled'}
        ref={tooltipRefUtilization}
      >
        <Progress
          aria-label={`resource-card-${cardId}-progress`}
          value={resourceUtilizationPercent}
          measureLocation={ProgressMeasureLocation.inside}
          size={ProgressSize.lg}
          variant={resourceProgressVariant()}
        />
      </div>
    </div>
  );
};

UtilizationProgress.propTypes = {
  cardId: PropTypes.string.isRequired,
  resourceUnits: PropTypes.arrayOf(
    PropTypes.shape({
      symbol: PropTypes.string,
      factor: PropTypes.number,
    })
  ).isRequired,
  resourceValue: PropTypes.oneOfType([
    PropTypes.number,
    PropTypes.oneOf([null]),
  ]),
  resourceUtilization: PropTypes.oneOfType([
    PropTypes.number,
    PropTypes.oneOf([null]),
  ]),
  isNewQuota: PropTypes.bool.isRequired,
  isEnabled: PropTypes.bool.isRequired,
};

UtilizationProgress.defaultProps = {
  resourceValue: 0,
  resourceUtilization: null,
};

export default UtilizationProgress;
