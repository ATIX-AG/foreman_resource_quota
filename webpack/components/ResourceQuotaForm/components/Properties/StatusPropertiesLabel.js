import PropTypes from 'prop-types';
import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { Label, Tooltip } from '@patternfly/react-core';

import withReactRoutes from 'foremanReact/common/withReactRoutes';

const NULL_COLOR = 'gray';
const NULL_TEXT = 'none';

const StatusPropertiesLabel = ({
  iconChild,
  statusContent,
  linkUrl,
  color,
  tooltipText,
}) => {
  const [text, setText] = useState(
    statusContent !== null ? statusContent : NULL_TEXT
  );
  const [iconColor, setIconColor] = useState(
    statusContent !== null ? color : NULL_COLOR
  );

  if (statusContent !== null && text !== `${statusContent}`) {
    setText(`${statusContent}`);
    setIconColor(color);
  }

  return (
    <Tooltip content={tooltipText}>
      <Label
        isCompact
        icon={iconChild}
        color={iconColor}
        render={({ className, content, componentRef }) => (
          <Link
            to={`${linkUrl}`}
            className={className}
            innerRef={componentRef}
            target="_blank"
            rel="noopener noreferrer"
          >
            {content}
          </Link>
        )}
      >
        {text}
      </Label>
    </Tooltip>
  );
};

StatusPropertiesLabel.defaultProps = {
  color: 'blue',
  statusContent: null,
};

StatusPropertiesLabel.propTypes = {
  iconChild: PropTypes.element.isRequired,
  statusContent: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.number,
    PropTypes.oneOf([null]),
  ]),
  linkUrl: PropTypes.string.isRequired,
  color: PropTypes.string,
  tooltipText: PropTypes.string.isRequired,
};

export default withReactRoutes(StatusPropertiesLabel);
