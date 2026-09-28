// Side-effect timing fixture: sync auth reset while live shell still probes (R1).

export function onLogout(store, shellApi) {
  // Synchronous reset while shell subscribers may still hold probe queries.
  store.dispatch(shellApi.util.resetApiState());
  store.dispatch({ type: "auth/clear" });
}

export function ShellMenu({ useGetMembershipQuery, userId }) {
  // Live actor: membership probe re-runs after reset and can rewrite auth.
  const { data } = useGetMembershipQuery({ userId });
  return data ? data.orgName : null;
}
