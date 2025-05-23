package uz.hayatbank.api.transport.result;

import lombok.Data;
import lombok.EqualsAndHashCode;
import uz.hayatbank.api.bean.UserBean;
import uz.hayatbank.api.transport.GenericResult;

@EqualsAndHashCode(callSuper = true)
@Data
public class SelfInfoResult extends GenericResult {
    private UserBean self;
}
