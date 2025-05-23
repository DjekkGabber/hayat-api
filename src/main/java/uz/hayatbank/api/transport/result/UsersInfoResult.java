package uz.hayatbank.api.transport.result;

import lombok.Data;
import lombok.EqualsAndHashCode;
import uz.hayatbank.api.bean.UserBean;
import uz.hayatbank.api.transport.GenericPagingResult;

import java.util.List;

@EqualsAndHashCode(callSuper = true)
@Data
public class UsersInfoResult extends GenericPagingResult {
    private List<UserBean> users;
}
