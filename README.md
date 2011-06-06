# Digestive functors for heist

# Deprecated in favor of combined library:
https://github.com/dbp/digestive-functors-snap-heist

## Comments on current state of the library
Right now, this only works with the specific snap backend that was built for it, at https://github.com/dbp/digestive-functors-snap-heist . This is due to a limitation in digestive-functors that prevents us from requesting a piece of the environment in any way other than using a field name like "prefix-fval[1]" or in the case of subforms "prefix-fval[1.1]". This is used to great effect by other frontend / backends, like Blaze, but means that the only way (thus for identified) of being able to get a field by name is to have the environment give back the entire params map (in response to a request for any param) and then have the frontend find the value in that. This means that the frontend depends on the backend behaving in a sort of funny way, which is why it needs to use the special backend built for it.

One way to alleviate this would be to make the FormId that is passed to the environment be polymorphic, restricted to, for example, something that can be turned into a string. The downsides of that is further complicating the code by being even more abstract, and, having to thread that type throughout.

Either way, this library should be seen as an early attempt to bring Digestive Functors (which are an amazingly powerful thing) to Heist, and NOT thought to be an ideal solution. 

What is set, and ideally should not change, is the actual interface for using them, specifically the splices that are provided. For each named input, splices "name-value" (just text of the value) and "name-error" which is a splice that renders subsplices with text assigned to the tag "error". ie: <name-error><error/></name-error>, since there is a list of errors provided. Future additions could allow that to be presented as text as well, concatenated with spaces or commas, in case someone wanted to use it as an attribute.

Also, right now you need to explicitly set the field name when specifying the errors as well. That should change, with a relatively simple implementation.

## Usage
    import Text.Digestive.Types
    import Text.Digestive.Backend.Snap.Heist
    import Text.Digestive.Validate
    import Text.Digestive.Heist
    import Text.Templating.Heist
    
    import Application
    
    data NewPassword = NewPassword String String String deriving (Eq,Show)
    
    passwordForm :: SnapForm Application Text [(Text, Splice Application)] NewPassword
    passwordForm = NewPassword
        <$> input "current" Nothing  `validate` checkPassword <++ errors "current"
        <*> input "new"     Nothing  `validate` nonEmpty      <++ errors "new"
        <*> input "confirm" Nothing  `validate` nonEmpty      <++ errors "confirm"
        
    changePasswordH = do r <- eitherSnapForm passwordForm "change-password-form"
                         case r of
                             Left splices' -> do
                               heistLocal (bindSplices splices') $ render "profile/usersettings/password"
                             Right password' -> do
                               render "profile/usersettings/password"

    <h3>Change Password</h3>
    <form-async action="/settings/password">
      <table>
        <tr><td class="label"><label for="current">Current:</label></td> <td><input name="current" type="password" />
          Value: <current-value/>
          </td></tr>
        <tr><td class="label"><label for="new">New:</label></td> <td><input name="new" type="password" />
          Value: <new-value/>
          Errors: <new-error><error/></new-error></td></tr>
        <tr><td class="label"><label for="confirm">Confirm:</label></td> <td><input name="confirm" type="password" />
          Value: <confirm-value/>
          Errors: <confirm-error><error/></confirm-error>
          <button type="submit" title=""/></td></tr>
      </table>
    </form-async>

