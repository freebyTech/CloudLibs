import React from 'react';
import {Link} from 'react-router-dom';

const Session = (props) => {
  const deleteButton = props.isOwner ?
    <input type="button" title="Delete This Session" className="btn btn-sm btn-danger" value="X" onClick={props.delete}/> :
    null;
  return (
    <li key={props.id} className="session">
      { (props.isOwner) 
        ? <h2><Link to={`/submission/${props.session.sessionId}`}>{props.session.title}</Link> {deleteButton}</h2>
        : <h2>{props.session.title}</h2> }
      <div>{props.session.abstract}</div>
    </li>
  );
}

export default Session;