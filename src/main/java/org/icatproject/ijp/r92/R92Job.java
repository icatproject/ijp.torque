package org.icatproject.ijp.r92;

import java.io.Serializable;
import java.util.Date;

import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;

@SuppressWarnings("serial")
@Entity
@NamedQueries({
		@NamedQuery(name = "R92Job.FIND_BY_USERNAME", query = "SELECT j FROM R92Job j WHERE j.username = :username ORDER BY j.submitDate DESC"),
		@NamedQuery(name = "R92Job.ID_BY_USERNAME", query = "SELECT j.id FROM R92Job j WHERE j.username = :username ORDER BY j.submitDate DESC"),
		@NamedQuery(name = "R92Job.FIND_INCOMPLETE", query = "SELECT j FROM R92Job j WHERE NOT j.status = 'C'") })
public class R92Job implements Serializable {

	public final static String FIND_BY_USERNAME = "R92Job.FIND_BY_USERNAME";
	public final static String FIND_INCOMPLETE = "R92Job.FIND_INCOMPLETE";
	public static final String ID_BY_USERNAME = "R92Job.ID_BY_USERNAME";;

	@Id
	private String id;

	private String status;

	private String username;

	@Temporal(TemporalType.TIMESTAMP)
	private Date submitDate;

	private String batchFilename;

	public String getExecutable() {
		return executable;
	}

	private String executable;
	private String batchUsername;
	private String workerNode;

	public R92Job() {
	}

	public String getId() {
		return id;
	}

	public void setId(String id) {
		this.id = id;
	}

	public String getUsername() {
		return username;
	}

	public void setUsername(String username) {
		this.username = username;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public Date getSubmitDate() {
		return submitDate;
	}

	public void setSubmitDate(Date submitDate) {
		this.submitDate = submitDate;
	}

	public String getBatchFilename() {
		return batchFilename;
	}

	public void setBatchFilename(String batchFilename) {
		this.batchFilename = batchFilename;
	}

	public void setExecutable(String executable) {
		this.executable = executable;
	}

	public String getBatchUsername() {
		return batchUsername;
	}

	public void setBatchUsername(String batchUsername) {
		this.batchUsername = batchUsername;

	}

	public String getWorkerNode() {
		return workerNode;
	}

	public void setWorkerNode(String workerNode) {
		this.workerNode = workerNode;
	}
}
