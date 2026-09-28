package com.example.repo;

import java.util.List;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;

/** Scoped finder declares List<String> but selects two columns (RT1). */
public interface InstallationRepository extends Repository<Installation, Long> {

  @Query("select i.uuid, i.name from Installation i where i.orgUuid = ?1")
  List<String> findUuidsByOrg(String orgUuid);

  /** Fleet sibling returns matching scalar selection — contrast with scoped method. */
  @Query("select i.uuid from Installation i")
  List<String> findAllUuids();
}
